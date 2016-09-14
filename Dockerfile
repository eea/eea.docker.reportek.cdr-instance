FROM eeacms/reportek-base-dr:1.1
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

ENV DATADICTIONARY_SCHEMAS_URL=http://dd.eionet.europa.eu/api/schemas/forObligation \
    UNS_NOTIFICATIONS=on \
    REDIS_DATABASE=1 \
    REDIS_HOSTNAME=redisdeploy \
    REPORTEK_DEPLOYMENT=CDR

COPY src/zope-setup.sh              \
     src/configure-additional.py    /
COPY src/sources.cfg                \
     src/cdr-instance.cfg           \
     src/base.cfg                   $ZOPE_HOME/

USER root
RUN ./install.sh
USER zope-www
