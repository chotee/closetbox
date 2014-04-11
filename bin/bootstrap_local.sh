#!/bin/bash

#echo "Nr of arguments: " $#
#echo Scriptname $0
#echo Coderepos $1
#echo options $2

DEFAULT_CODE_REPOS=https://github.com/chotee/closetbox.git
CLOSETBOX_HOME=/home/closetbox
if [[ $(which $0) == '' ]]; then
    CLOSETBOX_BASE=$(dirname $0)
else
    CLOSETBOX_BASE=$(dirname $(which $0))/..
fi


function do_update_packagelist {
    apt-get update
}

function do_install_dependencies {
    apt-get install --yes sudo git

}

function do_create_closetbox_user {
    # Create the closetbox user. This is the user with maintenance access to the machine.
    # To enable remote maintainance if a key is in /root/closetbox_ssh_admin_access.pub,
    # that key will have access to the machine.
    if [[ ! $(id closetbox) ]]; then
        sudo useradd -m closetbox
        echo "closetbox ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/closetbox
        chmod 700 /home/closetbox
        mkdir /home/closetbox/.ssh
        chown closetbox:closetbox /home/closetbox/.ssh
        if [[ -e /root/closetbox_ssh_admin_access.pub ]]; then
            cat /root/closetbox_ssh_admin_access.pub >> /home/closetbox/.ssh/authorized_keys
            rm /root/closetbox_ssh_admin_access.pub
        fi
    else
        echo "User closetbox already exists. Skipping creation."
    fi
}

function do_get_code_repository {
    # Clone the repository. If it already exists, run an update.
    if [[ $code_repos == '' || $code_repos == "default" ]]; then
        code_repos=$DEFAULT_CODE_REPOS
    fi
    if [[ ! -e /home/closetbox/closetbox ]]; then
        echo "Cloning $code_repos in $(pwd)"
        sudo -iu closetbox git clone $code_repos closetbox
        ( cd /home/closetbox/closetbox;
          sudo -u closetbox git submodule init;
          sudo -u closetbox git submodule update )
    else
        echo "Updating existing clone of $code_repos in $(pwd)"
        ( cd /home/closetbox/closetbox;
          sudo -u closetbox git checkout;
          sudo -u closetbox git submodule update )
    fi
}

function do_copy_configuration_file {
    cp -v $configuration_file closetbox/settings.ini
}

function do_bootstrap {
    cd $CLOSETBOX_BASE
    do_update_packagelist
    do_install_dependencies
    do_create_closetbox_user
    cd $CLOSETBOX_HOME
    do_get_code_repository
    do_copy_configuration_file
}

function main {
    echo "I will install the Closetbox on this machine."
    echo "This means a closetbox user will be installed and various services rolled out on the machine."
    if [[ $(id -u) != '0' ]]; then
        echo "I expected to be run as root. but I am run as $(id -un). ABORTING."
        exit 1
    fi
    do_bootstrap
}

code_repos=$1
configuration_file=$2
main