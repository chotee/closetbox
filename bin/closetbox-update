#!/bin/bash

CLOSETBOX_BASE=$HOME/closetbox/
PYENV=$CLOSETBOX_BASE/pyenv/

function update_ansible {
    $PYENV/bin/pip install ansible --upgrade
}

function update_closetbox {
    playbook=$PYENV/bin/ansible-playbook
    git pull
    git checkout
    cd $HOME/closetbox/ansible
    $playbook closetbox.yml
}

function main() {
    cd $CLOSETBOX_BASE
    update_ansible
    update_closetbox
}

main;