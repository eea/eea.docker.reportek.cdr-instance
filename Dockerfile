FROM eeacms/reportek-base-dr:1.0
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

ENV DATADICTIONARY_SCHEMAS_URL=http://dd.eionet.europa.eu/api/schemas/forObligation \
    UNS_NOTIFICATIONS=on \
    REDIS_DATABASE=1 \
    REDIS_HOSTNAME=redisdeploy \
    REPORTEK_DEPLOYMENT=CDR \
    NEW_RELIC_ENABLED=true \
    NEW_RELIC_ENVIRONMENT=development \
    NEW_RELIC_CONFIG_FILE=/opt/zope/newrelic.ini

COPY src/docker-setup.sh    /docker-setup.sh
COPY src/configure-additional.py    /configure-additional.py
COPY src/sources.cfg            $ZOPE_HOME/
COPY src/cdr-instance.cfg       $ZOPE_HOME/
COPY src/base.cfg               $ZOPE_HOME/

USER root
RUN ./install.sh
USER zope-www
