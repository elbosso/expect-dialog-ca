# expect-dialog-ca
This repository contains scripts meant to make managing an openssl ca less painful inside a terminal environment

## Content
This Project consists of Linux shell scripts - some of them are meant to be run from inside 
 the terminal by the user, some of them exist to be called from other
 scripts. Additionally, there is also a number of expect scripts:
 
### Linux scripts for the user
<dl>
  <dt>create_ca.sh</dt>
  <dd></dd>
  <dt>install_ca_certificate.sh</dt>
  <dd></dd>
  <dt>manage_certs.sh</dt>
  <dd></dd>
  <dt>reneq_cert_req.sh</dt>
  <dd></dd>
  <dt>request_certificate.sh</dt>
  <dd></dd>
  <dt>revoke_crl.sh</dt>
  <dd></dd>
  <dt>sign_request.sh</dt>
  <dd></dd>
</dl>

### Linux helper scripts
<dl>
  <dt>configure_gui.sh</dt>
  <dd></dd>
</dl>

### Expect scripts
* ca_csr.xpct
* ca_csr_with_key.xpct
* gen_crl.xpct
* req_from_cert.xpct
* revoke_cert.xpct
* sign_csr.xpct
* sign_csr_dry.xpct

## Dependencies
If you did not already deduce it from there being **Linux**
scripts - this project is meant to be used under Linux! 

Well, the scripts are meant to facilitate the management of
[OpenSSL CAs](https://www.openssl.org/docs/manpages.html) - OpenSSL
must obviously be installed for them to work.

The GUI for the scripts is done with the help of
[Expect](http://www.tcl.tk/man/expect5.31/expect.1.html) and 
[Dialog](https://linux.die.net/man/1/dialog) - so both of them must be
installed, too.

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
 
## Layout of CAs managed with the scripts
The project and the scripts therein adhere to the
directory layout as described and used in 
[Expert PKI Tutorial](http://pki-tutorial.readthedocs.io/en/latest/expert/).

The only (slight) difference is that we keep the CAs strictly separate:
Even if they are members of some sort of hierarchie (meaning some are Root CAs for others),
they should live in sibling directories.

## Use Cases

### Building a new Certificate Authority

### Signing Certificate Requests

### Revoking Certificates

### Managing Certificate Lifecycle

### Requesting Certificates
