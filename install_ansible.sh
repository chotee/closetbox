#!/bin/bash

echo "Script that installs ansiable on a fresh debian Install and prepare access to roll out the closetbox services."
echo "A user 'cb_updater' will have been added that ansiable will operate through."
echo "It will ask for the IP and root password."
echo "----"

function failure {
    echo "Something unexpected happend";
    exit 1
}

function send_cmd {
    local cmd=$1
    echo ">>> $cmd"
    echo -n "<<< "
    ret=$(sshpass -e ssh root@$dest_host $cmd | tee /proc/self/fd/2) || failure
}

function do_preparation {
    do_login
    do_update_debian
    do_install_auth
#    create_sshkeys()
    do_create_cb_updater
}

function do_login {
    echo "----"
    echo "Testing login works and has elevated rights."
    send_cmd "id -u"
    if [[ $ret != 0 ]]; then
        failure
    fi
}

function do_update_debian {
    echo "----"
    echo "Updating debian install"
    send_cmd "apt-get update"
    send_cmd "apt-get dist-upgrade --assume-yes"
}

function do_install_auth {
    echo "----"
    echo "Installing vector to control the server."
    send_cmd "apt-get install openssh-server sudo"
}

function do_create_cb_updater {
    send_cmd "id cb_updater || echo missing"
    if [[ $ret == "missing" ]] ; then
        send_cmd "sudo useradd -m cb_updater"
        send_cmd 'echo "cb_updater ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cb_updater'
    else
        echo "User cb_updater already exists. Skipping creation."
    fi
}

if [[ $# == 1 ]]; then
    dest_host=$1;
    echo "Machine to install on is: $dest_host"
else
    read -p "Enter IP or hostname of the machine: " dest_host;
fi
read -sp "Root password:" SSHPASS
export SSHPASS
echo ""
read -p "Starting preparation of $dest_host. Are you sure? [y|n]: " yn
case $yn in
    [Yy]* ) do_preparation;;
    [Nn]* ) echo "Aborted"; exit;;
    * ) echo "Please answer yes or no.";;
esac

echo "----"
echo "Don't forget to change the root password or enable sudo and disable root.login completely"
echo "Done."
