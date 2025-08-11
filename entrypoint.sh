#!/bin/bash
set -e

echo $JDBC_DRIVER

ls -l  */conf/META-INF/*

PERSISTENCE_CONF_FILE="sysml-v2-api-services/conf/META-INF/persistence.xml"
PERSISTENCE_NAMESPACE="http://java.sun.com/xml/ns/persistence"

echo "==== default persistence properties ===="
cat $PERSISTENCE_CONF_FILE | grep property

# Update JDBC and Hibernate properties if env vars are set
[ -n "$JDBC_DRIVER" ]          && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='javax.persistence.jdbc.driver']/@value" -v "$JDBC_DRIVER" "$PERSISTENCE_CONF_FILE"
[ -n "$JDBC_URL" ]             && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='javax.persistence.jdbc.url']/@value" -v "$JDBC_URL" "$PERSISTENCE_CONF_FILE"
[ -n "$JDBC_USER" ]            && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='javax.persistence.jdbc.user']/@value" -v "$JDBC_USER" "$PERSISTENCE_CONF_FILE"
[ -n "$JDBC_PASSWORD" ]        && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='javax.persistence.jdbc.password']/@value" -v "$JDBC_PASSWORD" "$PERSISTENCE_CONF_FILE"
[ -n "$HIBERNATE_DIALECT" ]    && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='hibernate.dialect']/@value" -v "$HIBERNATE_DIALECT" "$PERSISTENCE_CONF_FILE"
[ -n "$HIBERNATE_HBM2DDL" ]    && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='hibernate.hbm2ddl.auto']/@value" -v "$HIBERNATE_HBM2DDL" "$PERSISTENCE_CONF_FILE"
[ -n "$HIBERNATE_SHOW_SQL" ]   && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='hibernate.show_sql']/@value" -v "$HIBERNATE_SHOW_SQL" "$PERSISTENCE_CONF_FILE"
[ -n "$HIBERNATE_FORMAT_SQL" ] && xmlstarlet ed -P -L -N p=${PERSISTENCE_NAMESPACE} -u "//p:property[@name='hibernate.format_sql']/@value" -v "$HIBERNATE_FORMAT_SQL" "$PERSISTENCE_CONF_FILE"

echo "==== configured persistence properties ===="
cat $PERSISTENCE_CONF_FILE | grep property

exec "$@"
