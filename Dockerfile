FROM eeacms/reportek-base-dr:latest
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

ENV DATADICTIONARY_SCHEMAS_URL=http://dd.eionet.europa.eu/api/schemas/forObligation \
    UNS_NOTIFICATIONS=on \
    REDIS_DATABASE=1 \
    REDIS_HOSTNAME=redisdeploy \
    REPORTEK_DEPLOYMENT=CDR

COPY src/sources.cfg            $ZOPE_HOME/
COPY src/cdr-instance.cfg       $ZOPE_HOME/
COPY src/base.cfg               $ZOPE_HOME/

USER root
RUN ./install.sh
USER zope-www
