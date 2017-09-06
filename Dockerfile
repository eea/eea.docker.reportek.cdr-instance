FROM eeacms/reportek-base-dr:1.9.6
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

ENV DATADICTIONARY_SCHEMAS_URL=http://dd.eionet.europa.eu/api/schemas/forObligation \
    UNS_NOTIFICATIONS=on \
    REDIS_DATABASE=1 \
    REDIS_HOSTNAME=redisdeploy \
    REPORTEK_DEPLOYMENT=CDR

COPY src/sources.cfg                \
     src/cdr-instance.cfg           \
     src/base.cfg                   $ZOPE_HOME/

USER root
COPY . /opt/app
RUN install-dependencies /opt/app

WORKDIR /var/local

RUN curl "http://download.osgeo.org/geos/geos-3.3.8.tar.bz2" -o "/var/local/geos-3.3.8.tar.bz2" && \
    tar -jxvf geos-3.3.8.tar.bz2 && rm geos-3.3.8.tar.bz2 && \
    cd geos-3.3.8 && \
    CFLAGS="-m64" CPPFLAGS="-m64" CXXFLAGS="-m64" LDFLAGS="-m64" FFLAGS="-m64" LDFLAGS="-L/usr/lib64/" ./configure && \
    make && make check && make install clean && cd /var/local && rm -rf geos-3.3.8 && \

    curl "http://download.osgeo.org/proj/proj-4.8.0.tar.gz" -o "/var/local/proj-4.8.0.tar.gz" && \
    cd /var/local && tar -zxvf proj-4.8.0.tar.gz && rm proj-4.8.0.tar.gz && cd proj-4.8.0 && \
    ./configure && make && make install clean && cd /var/local && rm -rf proj-4.8.0 && \

    curl "http://www.gaia-gis.it/gaia-sins/freexl-1.0.3.tar.gz" -o "/var/local/freexl-1.0.3.tar.gz" && \
    cd /var/local && tar -zxvf freexl-1.0.3.tar.gz && rm freexl-1.0.3.tar.gz && cd freexl-1.0.3 && \
    ./configure && make && make install clean && cd /var/local && rm -rf freexl-1.0.3 && \

    curl "http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-4.1.0.tar.gz" -o "/var/local/libspatialite-4.1.0.tar.gz" && \
    cd /var/local && tar -zxvf libspatialite-4.1.0.tar.gz && rm libspatialite-4.1.0.tar.gz && cd libspatialite-4.1.0 && \
    ./configure && make && make install clean && cd /var/local && rm -rf libspatialite-4.1.0 && \

    curl "http://www.gaia-gis.it/gaia-sins/readosm-1.0.0e.tar.gz" -o "/var/local/readosm-1.0.0e.tar.gz" && \
    cd /var/local && tar -zxvf readosm-1.0.0e.tar.gz && rm readosm-1.0.0e.tar.gz && cd readosm-1.0.0e && \
    ./configure && make && make install clean && cd /var/local && rm -rf readosm-1.0.0e && \

    curl "http://www.gaia-gis.it/gaia-sins/spatialite-tools-sources/spatialite-tools-4.1.0.tar.gz" -o "/var/local/spatialite-tools-4.1.0.tar.gz" && \
    cd /var/local && tar -zxvf spatialite-tools-4.1.0.tar.gz && rm spatialite-tools-4.1.0.tar.gz && cd spatialite-tools-4.1.0 && \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" ./configure && make && make install clean && \
    cd /var/local && rm -rf spatialite-tools-4.1.0 && \

    svn co "https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/CDDA/2013/cdda-spatialite/" && \
    chown -R 500:500 /var/local/cdda-spatialite

WORKDIR $ZOPE_HOME
RUN ./install.sh
USER zope-www
