==========
Closet Box
==========

Scripts and setup for getting running our own online-services.

Makes use of ansible for repeatable installs on Debian.

Goals
-----

#. Simple setup

#. Good security, while still maintaining normal functionalities.

Tools
-----

closetbox_bootstrap.sh: The Script closetbox_bootstrap.sh will ask for IP and root password, after which it will
insert a "closetbox" use that has rights to maintain the machine. Access is done via SSH key authentication.


Questions
---------

#. How to handle key-material.

#. How to handle list of servers to maintain.