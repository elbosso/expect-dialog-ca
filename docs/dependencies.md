## Dependencies
If you did not already deduce it from there being **Linux**
scripts - this project is meant to be used under Linux! At the moment, the only variant it has been extensively tested 
in is Ubuntu in its latest long term support version: 18.04.

Well, the scripts are meant to facilitate the management of
[OpenSSL CAs](https://www.openssl.org/docs/manpages.html) - OpenSSL
must obviously be installed for them to work.

The GUI for the scripts is done with the help of
[Expect](http://www.tcl.tk/man/expect5.31/expect.1.html) and 
[Dialog](https://linux.die.net/man/1/dialog) - so both of them must be
installed, too.

*But be wary: Ubuntu might try and sneak a SNAP version past you, for example for `expect`. Don't
use that! it is dangerous and crappy and does not work as the normal binary. Always use the binary!*

At times apt might tell you that it does not find an installation candidate for either
`expect` or `dialog`. The reason for this is in most cases deactivation of universe and multiverse
repositories (usually in _/etc/apt/sources.list_) - activate them, followed by an `apt update` and Ubuntu should know once again
where to finde the needed packages...

Depending on your particular flavour/version of Linux, there are
 maybe even more components/packages needed to be installed
 to get the scripts working...

For operating the scripts, the
[GIT command line client](https://git-scm.com/) is crucial - expecially
for setting up new CAs (see next dependency below).
 
A further dependency is on the work of 
[Stefan H. Holek](https://bitbucket.org/stefanholek/), especially
on his work on the 
[Expert PKI Tutorial](https://bitbucket.org/stefanholek/pki-example-3).
This does not necessarily mean that the computer on which the
PKI is worked needs that connection - the content of the repository can be downloaded 
someplace else and then copied over (see Use Case for
Creating a CA further down). 

There is one more *optional* dependency:
The creation of private keys needs some form of protecting them. The scripts
in this project use passwords for that. To facilitate choosing safe
passwords, the scripts use 
[makepasswd](https://www.cyberciti.biz/faq/generating-random-password/) 
when and if available. So if
you want to have the amenity of proposed passwords, you have to make sure
that it is installed.
 
## Layout of CAs managed with the scripts
The project and the scripts therein adhere to the
directory layout as described and used in 
[Expert PKI Tutorial](http://pki-tutorial.readthedocs.io/en/latest/expert/).

The only (slight) difference is that we keep the CAs strictly separate:
Even if they are members of some sort of hierarchie (meaning some are Root CAs for others),
they should live in sibling directories.
