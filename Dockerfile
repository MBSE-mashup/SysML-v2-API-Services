# Multi-stage Dockerfile for SysML v2 API Services
# Rootless and OpenShift-compatible

# Stage 1: Build stage
FROM sbtscala/scala-sbt:openjdk-11u2_1.9.8_2.13.12 as builder

# Switch to non-root user for building (if not already)
USER 1001

# Install git for cloning repository (using package manager as root, then switch back)
USER root
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Switch back to non-root user
USER 1001

# Set working directory with proper permissions
WORKDIR /tmp/app

# Clone the repository
RUN git clone https://github.com/Systems-Modeling/SysML-v2-API-Services.git .

# Alternative: Copy local source code instead of cloning
# COPY --chown=1001:1001 . .

# Warm up sbt and download dependencies
RUN sbt update

# Build the project
RUN sbt clean compile

# Run tests
RUN sbt test

# Create distribution
RUN sbt dist

# Extract the distribution to a location accessible by next stage
RUN unzip target/universal/sysml-v2-api-services-*.zip -d /tmp/ && \
    mv /tmp/sysml-v2-api-services-* /tmp/sysml-v2-api-services

# Stage 2: Runtime stage - fully rootless
FROM registry.access.redhat.com/ubi8/openjdk-11-runtime

# Set environment variables including database configuration
ENV JAVA_OPTS="-Xmx1g -Xms512m -XX:+UseG1GC" \
    PLAY_CONF_FILE=application.conf \
    APP_HOME=/opt/app \
    DB_HOST=localhost \
    DB_PORT=5432 \
    DB_NAME=sysml \
    DB_USER=sysml \
    DB_PASSWORD=sysml \
    DB_URL="" \
    CONNECTION_POOL_SIZE=10

# Create application directory with proper permissions for arbitrary user ID
USER root
RUN mkdir -p ${APP_HOME} && \
    chgrp -R 0 ${APP_HOME} && \
    chmod -R g=u ${APP_HOME}

# Copy the built application from builder stage
COPY --from=builder --chown=1001:0 /tmp/sysml-v2-api-services ${APP_HOME}/

# Make startup script executable for group
RUN chmod g+x ${APP_HOME}/bin/sysml-v2-api-services

# Set working directory
WORKDIR ${APP_HOME}

# Switch to non-root user (OpenShift will override this with arbitrary UID)
USER 1001

# Expose the default Play Framework port
EXPOSE 9000

# Health check (using wget instead of curl for UBI compatibility)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:9000/health || exit 1

# Start the application with database configuration
CMD ["bin/sysml-v2-api-services", \
     "-Dplay.http.secret.key=${PLAY_SECRET_KEY:-changeme}", \
     "-Dplay.server.http.port=9000", \
     "-Dplay.server.http.address=0.0.0.0", \
     "-Ddb.default.driver=org.postgresql.Driver", \
     "-Ddb.default.url=${DB_URL:-jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}}", \
     "-Ddb.default.username=${DB_USER}", \
     "-Ddb.default.password=${DB_PASSWORD}", \
     "-Ddb.default.hikaricp.maximumPoolSize=${CONNECTION_POOL_SIZE}"]

# OpenShift-specific labels
LABEL name="sysml-v2-api-services" \
      maintainer="SysML v2 API Services" \
      version="1.0" \
      description="Rootless Docker image for SysML v2 API Services built with Play Framework" \
      summary="SysML v2 API Services - OpenShift Compatible" \
      io.k8s.description="SysML v2 API Services running on Play Framework" \
      io.k8s.display-name="SysML v2 API Services" \
      io.openshift.expose-services="9000:http" \
      io.openshift.tags="java,scala,play,sysml,api" \
      base.image="sbtscala/scala-sbt:openjdk-11u2_1.9.8_2.13.12" \
      java.version="11" \
      scala.version="2.13.12" \
      sbt.version="1.9.8"
