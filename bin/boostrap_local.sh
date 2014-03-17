#!/bin/bash

CLOSETBOX_BASE=$(dirname $(which $0))/..
KEY_MATERIAL=keys # where to store the keys to the machines.

function do_install_sudo {
    apt-get install sudo
}

function do_create_closetbox_user {
    if [[ ! $(id closetbox) ]]; then
        sudo useradd -m closetbox
        echo "closetbox ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/closetbox
        chmod 700 /home/closetbox
        mkdir /home/closetbox/.ssh
        chown closetbox:closetbox /home/closetbox/.ssh
    else
        echo "User closetbox already exists. Skipping creation."
    fi
}

function do_test_closetbox_user_access {
    closet_cmd 'id -u' # Can login
    closet_cmd 'sudo id -u' # can sudo successfully
    if [[ $ret == 0 ]]; then
        echo "Obtained machine administrative access."
    else
        failure;
    fi
}

function do_get_code_repository {
    sudo apt-get --yes install git
    if [[ $git_repos == '' ]]; then
        git_repos=https://github.com/chotee/closetbox.git
    fi
    sudo -iu closetbox git clone $git_repos closetbox
}

function do_installation {
    do_install_sudo
    do_create_closetbox_user
    do_get_code_repository
    sudo -iu closetbox bash /home/closetbox/closetbox/bin/closetbox_install
}

function main {
    cd $CLOSETBOX_BASE
    echo "I will install the Closetbox on this machine."
    echo "This means a closetbox user will be installed and various services rolled out on the machine."
    if [[ $(id -u) != '0' ]]; then
        echo "I expected to be run as root. but I am run as $(id -un). ABORTING."
        exit 1
    fi
    do_installation
}

git_repos=$1
main;