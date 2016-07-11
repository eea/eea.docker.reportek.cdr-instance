#!/bin/bash

cd $ZOPE_HOME

LAST_CFG=`./bin/develop rb -n`
echo $LAST_CFG

# Avoid running buildout on docker start
if [[ "$LAST_CFG" == *base.cfg ]]; then
  if ! test -e $ZOPE_HOME/buildout.cfg; then
      python /configure-additional.py
      python /configure.py
  fi

  if test -e $ZOPE_HOME/buildout.cfg; then
      ./bin/buildout -c buildout.cfg
  fi
fi

# Cleanup stale PID file
rm -vf ${ZOPE_HOME}/var/instance.pid
