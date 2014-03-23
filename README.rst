==========
Closet Box
==========

Scripts and setup for getting running our own online-services.

Goals
=====

#. One command installation on different hardware.
#. Decent security, while still maintaining normal functionally.
#. Use the services directly or as the basis for further configuration.

Software and Technology
=======================

Services
--------

* File and documentsharing via Owncloud_

.. _Owncloud: https://owncloud.org/

Infrastructure
--------------

* The operating system is Debian_ (A GNU/Linux distribution)
* Ansible_ for the installation process.
* Nginx_ lightweight webserver
* NTP_ client for stable time reference

.. _Debian: https://www.debian.org/
.. _Ansible: http://www.ansible.com/home
.. _Nginx: https://nginx.org/
.. _NTP: http://www.ntp.org/

Security and hardening
----------------------

* Fail2ban_ to hinder bruteforcing user passwords

.. _Fail2ban: Fail2ban http://www.fail2ban.org


Deploying
=========

Closetbox can either be deployed directly on the machine that will run the services or it is possible to
deploy from a remote machine.

In either case, a user ``closetbox`` is added to the system. This user has administrative access to the machine and
a full copy of the Closetbox code in it's homedir.

Deploying Closetbox Locally
---------------------------

To install a new closetbox on the closetbox itself. You start out being *root* and do::

 # wget -qO - https://raw.github.com/chotee/closetbox/master/bin/bootstrap_local.sh | bash

or, a shorter version, to save typing -::

 # wget -qO - https://tinyurl.com/ocmra2r | bash

This will add a "closetbox" user that installs all of the magic.

If you are uncomfortable with running random scripts as root, you can also install Git, clone the repository::

$ git clone https://github.com/chotee/closetbox.git

and run closetbox/bin/bootstrap_local.sh . This will do the same installation but all of the code is available for review.

Deploying Closetbox Remotely
----------------------------

In the case you have multiple machines to deploy or want to do future service on machines from one central location,
you can also do a remote deployment. An sshd server should be already on the target machine.

To do this, do the following::

 $ git clone https://github.com/chotee/closetbox.git # Clone the repository
 $ mkdir closetbox/keys # make a directory for the remote administration key material.
 $ closetbox/bin/bootstrap_remote.sh # Run once per machine to install.

``bootstrap_remote.sh`` will ask for you for the hostname/IP address and root password of the machine. After installation
administrative access can be gained by using the keys in closetbox/keys . Each installed machine has it's own
administrative keypair. The keys are named after the hostname of the remote machine.

Administrative access to a machine can be obtained via::

$ ssh -i closetbox/keys/postbox_ecdsa closetbox@192.168.122.108 # access machine named postbox on 192.168.122.108

Deploying from an alternative repository
----------------------------------------

The default code repository for closetbox is https://github.com/chotee/closetbox.git . However, if you have want to
