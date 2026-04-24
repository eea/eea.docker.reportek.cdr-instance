# syntax=docker/dockerfile:1
# Docker Hardened Images (DHI) for Zope / Reportek CDR

FROM eeacms/reportek-base-dr:z5-1.4

USER root

# Inject CDR Specific Zope Configuration Map
COPY src/site.zcml /opt/zope/etc/site.zcml

ENV DATADICTIONARY_SCHEMAS_URL=http://dd.eionet.europa.eu/api/schemas/forObligation \
    UNS_NOTIFICATIONS=on \
    REPORTEK_DEPLOYMENT=CDR

RUN chown ${ZOPE_UID}:${ZOPE_GID} /opt/zope/etc/site.zcml

USER zope-www
