#!/bin/bash

CLOSETBOX_BASE=$(dirname $(which $0))/..
KEY_MATERIAL=keys # where to store the keys to the machines.


function failure {
    echo "Something unexpected happend";
    exit 1
}

function send_cmd {
    # Send a command as root.
    local cmd=$1
    echo ">>> $cmd"
    echo -n "<<< "
    ret=$(sshpass -e ssh root@$dest_host $cmd | tee /proc/self/fd/2) || failure
    echo
}

function closet_cmd {
    # Send command as the closetbox administrative user.
    local cmd=$1
    echo ">>> $cmd"
    echo -n "<<< "
    ret=$(ssh -i $cb_keyfile closetbox@$dest_host $cmd | tee /proc/self/fd/2) || failure
    echo
}

function send_file {
    # send the file $1 to the machine being installed storing it as $2.
    local src_location=$1
    local dest_location=$2
    echo "Remote copy '${src_location}' to '${dest_location}'"
    ret=$(sshpass -e scp ${src_location} root@$dest_host:${dest_location} | tee /proc/self/fd/2) || failure
    echo "Copied."
}

function get_remote_hostname {
    # Test the connection to the machine and check that we have elevated rights.
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

function create_admin_sshkeys {
    # Create a administrative keypair that will be used to gain access to the machine in the future
    # one keypair per machine.
    cb_keyfile="${KEY_MATERIAL}/${cb_hostname}_ecdsa"
    cb_keyfile_pub="${cb_keyfile}.pub"
    if [ ! -e ${cb_keyfile} ]; then
        ssh-keygen -t ecdsa -b 521 -N '' -C "${cb_hostname}@closetbox_maint" -f $cb_keyfile || failure
    else
        echo "A closetbox key already exists for this host. Reusing."
    fi
}

function send_admin_sshkeys {
    send_file $cb_keyfile_pub "/root/closetbox_ssh_admin_access.pub" || failure
}

function prepare_closetbox {
    send_file bin/bootstrap_local.sh "/root/closetbox_bootstrap_local.sh" || failure
    if [[ -z $code_repos ]]; then
        code_repos='default'
    fi
    send_cmd "bash /root/closetbox_bootstrap_local.sh $code_repos no_install" || failure
}

function test_closetbox_user_access {
    closet_cmd 'id -u' # Can login
    closet_cmd 'sudo id -u' # can sudo successfully
    if [[ $ret == 0 ]]; then
        echo "Obtained machine administrative access."
    else
        failure;
    fi
}

function install_closetbox {
    closet_cmd 'bash /home/closetbox/closetbox/bin/closetbox_install'
}


function do_preparation {
    get_remote_hostname
    create_admin_sshkeys
    send_admin_sshkeys
    prepare_closetbox
    test_closetbox_user_access
    install_closetbox
#    do_gpg_get_keys
#    do_add_backup_policies
}

function main {
    # Fix the working directory to a known location.
    cd $CLOSETBOX_BASE
    echo "Script that installs ansiable on a fresh Debian install and prepare access to roll out the closetbox services."
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
code_repos=$2
main;
