FROM eeacms/zope:2.13.22
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

ENV EVENT_LOG_LEVEL INFO
ENV Z2_LOG_LEVEL INFO
ENV ZEO_CLIENT true
ENV ZEO_ADDRESS zeoserver:8100
ENV BLOB_CACHE_SIZE 500000000
ENV LOCAL_CONVERTERS_HOST converter
ENV DATADICTIONARY_SCHEMAS_URL http://dd.eionet.europa.eu/api/schemas/forObligation
ENV UNS_NOTIFICATIONS on
ENV REDIS_DATABASE 1
ENV REDIS_HOSTNAME redisdeploy
ENV REPORTEK_DEPLOYMENT CDR

COPY src/versions.cfg           $ZOPE_HOME/
COPY src/sources.cfg            $ZOPE_HOME/
COPY src/cdr-instance.cfg       $ZOPE_HOME/
COPY src/base.cfg               $ZOPE_HOME/

USER root
RUN ./install.sh && chown -R 500:500 $ZOPE_HOME
USER zope-www
