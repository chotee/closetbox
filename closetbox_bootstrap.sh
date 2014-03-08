#!/bin/bash

KEY_MATERIAL='keys' # where to store the keys to the machines.

function failure {
    echo "Something unexpected happend";
    exit 1
}

function send_cmd {
    local cmd=$1
    echo ">>> $cmd"
    echo -n "<<< "
    ret=$(sshpass -e ssh root@$dest_host $cmd | tee /proc/self/fd/2) || failure
    echo
}

function closet_cmd {
    local cmd=$1
    echo ">>> $cmd"
    echo -n "<<< "
    ret=$(ssh -i $cb_keyfile closetbox@$dest_host $cmd | tee /proc/self/fd/2) || failure
    echo
}

function send_file {
    local src_location=$1
    local dest_location=$2
    echo "Remote copy '${src_location}' to '${dest_location}'"
    ret=$(sshpass -e scp ${src_location} root@$dest_host:${dest_location} | tee /proc/self/fd/2) || failure
    echo "Copied."
}

function do_login {
    echo "----"
    echo "Testing login works and has elevated rights."
    send_cmd "id -u"
    if [[ $ret != 0 ]]; then
        failure
    fi
    send_cmd "hostname --short"
    cb_hostname=$ret
    echo "Closetbox hostname is '${cb_hostname}'"
}

function do_install_sudo {
    echo "----"
    echo "Installing vector to control the server."
    send_cmd "apt-get install sudo"
}

function create_sshkeys {
    cb_keyfile="${KEY_MATERIAL}/${cb_hostname}_ecdsa"
    cb_keyfile_pub="${cb_keyfile}.pub"
    if [ ! -e ${cb_keyfile} ]; then
        ssh-keygen -t ecdsa -b 521 -N '' -C "${cb_hostname}@closetbox_maint" -f $cb_keyfile
    else
        echo "A closetbox key already exists for this host. Reusing."
    fi
}

function do_create_closetbox_user {
    send_cmd "id closetbox || echo missing"
    if [[ $ret == "missing" ]] ; then
        send_cmd "sudo useradd -m closetbox"
        send_cmd 'echo "closetbox ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/closetbox'
        send_cmd "mkdir /home/closetbox/.ssh"
        send_file "$cb_keyfile_pub" "/home/closetbox/.ssh/authorized_keys"
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

function do_install_ansible {
    closet_cmd "sudo apt-get --yes install python-pip python-dev"
    closet_cmd "sudo pip install ansible --no-allow-insecure"
    closet
}

function do_preparation {
    do_login
    do_install_sudo
    create_sshkeys
    do_create_closetbox_user
    do_test_closetbox_user_access
#    do_install_ansible
}

function main {
    echo "Script that installs ansiable on a fresh debian Install and prepare access to roll out the closetbox services."
    echo "A user 'closetbox' will have been added that ansiable will operate through."
    echo "It will ask for the IP and root password."
    echo "----"

    if [ ! -z $dest_host ]; then
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
    echo "Don't forget to change the root password or"
    echo "use sudo and disable root login completely"
    echo "Done."
}

dest_host=$1;
main;
