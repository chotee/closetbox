#!/bin/bash

CLOSETBOX_BASE=$HOME/closetbox

function do_install_ansible {
    sudo apt-get install --yes python-pip python-dev python-virtualenv python-apt python-pycurl || exit 1
    virtualenv pyenv || exit 1
    pyenv/bin/pip install ansible || exit 1
}

function do_install_closetbox {
    bin/closetbox_update.sh
}

function do_install {
    cd $CLOSETBOX_BASE
    do_install_ansible
    do_install_closetbox
}

function main {
    echo "I will install the Closetbox on this machine."
    echo "Various services will be rolled out on the machine."
    do_install
}

main
