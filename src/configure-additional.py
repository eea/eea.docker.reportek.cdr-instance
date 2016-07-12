#!/usr/bin/python
""" Extra configuration:
    Generate newrelic.ini based on environment vars values
    or default ones
"""

import os
import io

ZOPE_HOME = os.environ.get('ZOPE_HOME', '/opt/zope')

NEW_RELIC_ENABLED = os.environ.get("NEW_RELIC_ENABLED", False)
IS_NEW_RELIC_ENABLED = True if NEW_RELIC_ENABLED == 'true' or \
    NEW_RELIC_ENABLED is True else False
NEW_RELIC_ENV_VARS_PREFIX = "NEW_RELIC-"
NEW_RELIC_INI_FILE = "newrelic.ini"

NEW_RELIC_SETTINGS = {
    'license_key': {
        'name': 'license_key',
        'default': 'LICENSE KEY MISSING.'
    },
    'app_name': {
        'name': 'app_name',
        'default': 'CDR-Local:instance-YES_DOCKER_1'
    },
    'monitor_mode': {
        'name': 'monitor_mode',
        'default': 'true'
    },
    'log_file': {
        'name': 'log_file',
        'default': '/tmp/newrelic-python-agent.log'
    },
    'log_level': {
        'name': 'log_level',
        'default': 'debug'
    },
    'ssl': {
        'name': 'ssl',
        'default': 'false'
    },
    'high_security': {
        'name': 'high_security',
        'default': 'false'
    },
    'transaction_tracer_enabled': {
        'name': 'transaction_tracer.enabled',
        'default': 'true'
    },
    'transaction_tracer_transaction_threshold': {
        'name': 'transaction_tracer.transaction_threshold',
        'default': 'apdex_f'
    },
    'transaction_tracer_record_sql': {
        'name': 'transaction_tracer.record_sql',
        'default': 'obfuscated'
    },
    'transaction_tracer_stack_trace_threshold': {
        'name': 'transaction_tracer.stack_trace_threshold',
        'default': '0.5'
    },
    'transaction_tracer_explain_enabled': {
        'name': 'transaction_tracer.explain_enabled',
        'default': 'true'
    },
    'transaction_tracer_explain_threshold': {
        'name': 'transaction_tracer.explain_threshold',
        'default': '0.5'
    },
    'error_collector_enabled': {
        'name': 'error_collector.enabled',
        'default': 'true'
    },
    'browser_monitoring_auto_instrument': {
        'name': 'browser_monitoring.auto_instrument',
        'default': 'true'
    },
    'thread_profiler_enabled': {
        'name': 'thread_profiler.enabled',
        'default': 'true'
    },
}


def generate_newrelic_ini():
    """ Generate newrelic.ini file based on existing values saved in
        environment vars or possible default values from NEW_RELIC_SETTINGS

        Example:
        To set browser_monitoring.auto_instrument = false we will set
        NEW_RELIC-BROWSER_MONITORING_AUTO_INSTRUMENT = false
    """
    with io.FileIO(NEW_RELIC_INI_FILE, "w") as file:
        file.write("[newrelic]\n")

        for key in NEW_RELIC_SETTINGS:
            env_var_name = NEW_RELIC_ENV_VARS_PREFIX + key.upper()
            file.write(
                NEW_RELIC_SETTINGS[key]['name'] +
                " = " +
                os.environ.get(
                    env_var_name, NEW_RELIC_SETTINGS[key]['default']) + "\n"
            )


def init_new_relic():
    """ Init new relic settings if enabled
    """
    if IS_NEW_RELIC_ENABLED is True:
        generate_newrelic_ini()

init_new_relic()
