ARG BASEIMAGETAG=openjdk-11.0.16_1.7.2_2.13.9
FROM sbtscala/scala-sbt:$BASEIMAGETAG AS builder
ARG BASEIMAGETAG

# found Dockerfile inspiration at https://github.com/Systems-Modeling/SysML-v2-API-Services/issues/115
# according to docker hub docu of sbtscala/scala-sbt the images are tagged according to
# versions like: <JDK version>_<sbt version>_<Scala version>

RUN java --version && sbt --version && scala -version

WORKDIR /app

COPY build.sbt /app/
COPY project /app/project
RUN sbt update

COPY app /app/app
COPY conf /app/conf
COPY generated /app/generated
COPY public /app/public
COPY test /app/test

RUN sbt update

RUN sbt -v clean

# RUN sbt -v compile
# explicitly set memory available to jvm and avoid parallel compilation to make
# the build process inside the container more robust.
RUN sbt -J-Xmx1G -Dsbt.parallelExecution=false -v compile

# Create distribution
RUN sbt -J-Xmx1G -Dsbt.parallelExecution=false dist

#  --- Runtime stage ---
FROM openjdk:11-jre-slim
# we could also use the same baseimage as for building
# FROM sbtscala/scala-sbt:$BASEIMAGETAG

WORKDIR /app
# Copy and extract the distribution from the builder stage
COPY --from=builder /app/target/universal/*.zip /app/
RUN apt-get update && apt-get install -y unzip
RUN unzip /app/sysml-*.zip -d /app && mv /app/sysml-v2-api-services*/ /app/sysml-v2-api-services && rm /app/sysml-*.zip

# xmlstarlet is used by the entrypoint script to configure the service at
# launch-time, based on environment variables 
RUN apt-get --quiet --yes update &&  apt-get install -yqq wget xmlstarlet

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/sysml-v2-api-services/bin/sysml-v2-api-services"]
