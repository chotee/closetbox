==========
Closet Box
==========

Scripts and setup for getting running our own online-services.

Makes use of ansible for repeatable installs on Debian.

Goals
-----

#. Simple setup
#. Good security, while still maintaining normal functionalities.

Deploying
---------

To install a new closetbox, on the closetbox itself be *root* and do:
wget -qO - https://raw.github.com/chotee/closetbox/master/bin/boostrap_local.sh | bash
- or to save typing -
wget -qO - http://tinyurl.com/closetbox-bs | bash

This will install a "closetbox" user that installs all of the magic.

