#!/usr/bin/env python

TEMPLATE_URL="https://raw.githubusercontent.com/chotee/closetbox/master/settings_template.ini"

import os, sys
import tempfile
from subprocess import call
import optparse
from ConfigParser import SafeConfigParser, Error as ConfigParserError
import logging

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)

CmdLineConfig = None

def main():
    parse_cmdline()
    introduction()
    run_as_root()
    config_file = get_template()
    config = edit_template(config_file)
    start_bootstrap(config_file, config)
    kickoff_installation()

def introduction():
    print """\nHi there,
I will start the installation of Closetbox on this machine.
Before we can get to the installation however, I will need to know a few
extra things. That's why I will start an editor with a default template.
Most things you can just leave as they are and it should just work.
"""
    if not CmdLineConfig.yes:
        raw_input("Press enter to continue.")

def parse_cmdline():
    global CmdLineConfig
    parser = optparse.OptionParser()
    parser.add_option("-t", "--template", metavar="URL", default=TEMPLATE_URL,
                      help="URL of the template to use for the configuration file.")
    parser.add_option('-v', '--verbose', action="store_true",
                      help="Make the script output more verbose.")
    parser.add_option('-y', '--yes', action="store_true",
                      help="Assume yes to everything, do not stop for interaction.")

    (CmdLineConfig, args) = parser.parse_args()
    if CmdLineConfig.verbose:
        log.setLevel(logging.DEBUG)
    if CmdLineConfig.yes:
        log.info("Assuming 'yes' to all questions.")

def run_as_root():
    """Check if the process is being run as root and stop otherwise."""
    log.info(run_as_root.__doc__)
    if os.getuid() == 0:
        return True
    else:
        die("You need to run this script as root. Maybe you forgot to run it with sudo?")


def obtain_file(template_url):
    if template_url.startswith("http"):
        conf_file = tempfile.NamedTemporaryFile(delete=False).name  # Create a temporary file
        log.info("Requesting file from '%s'." % template_url)
        cmd = ['wget', '-qO', conf_file, template_url]
        log.debug(cmd)
        ret_code = call(cmd)  # Get and store the template of the configuration file.
    else:
        conf_file = template_url
        log.info("Directly using local file '%s'." % conf_file)
    return conf_file


def get_template():
    """Get the template and store it in a temporary file."""
    log.info(get_template.__doc__)
    # We use wget, since we DO want proper https checking.
    template_url = CmdLineConfig.template
    conf_file = obtain_file(template_url)
    return conf_file

def edit_template(conf_file):
    """Start a text editor and check the file for syntax errors."""
    if CmdLineConfig.yes:
        return
    call(['editor', conf_file])
    try:
        config = SafeConfigParser()
        config.read(conf_file)
    except ConfigParserError, ex:
        log.error("Something seems to be wrong with the configuration file\n%s\nPlease correct it first.", ex)
        raw_input("Press enter to return to the editor.")
        edit_template(conf_file)
    return config

def start_bootstrap(conf_file, config):
    bootstrap_url = config.get('bootstrap', 'script_url')
    repository_url = config.get('bootstrap', 'repository_url')
    bootstrap_script = obtain_file(bootstrap_url)
    cmd = ['bash', bootstrap_script,  repository_url, os.path.abspath(conf_file)]
    log.debug(cmd)
    call(cmd)

def kickoff_installation():
    cmd = 'sudo -iu closetbox bash /home/closetbox/closetbox/bin/closetbox_install.sh'.split()
    log.debug(cmd)
    call(cmd)

def die(msg=None):
    """I get called when something went wrong and we need to exit."""
    print " !!!!!!!! "
    if msg:
        print "\n" + msg
    print "Stopping installation.\n"
    sys.exit(1)


if __name__ == '__main__':
    main()
