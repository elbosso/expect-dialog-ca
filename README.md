# expect-dialog-ca
This repository contains scripts meant to make managing an openssl ca less painful inside a terminal environment

## Scope
The components contained inside this project ease the use of openssl to create and maintain
essential parts of a public key infrastructure (PKI) - 
namely the certificate Authorities (CAs). The scripts 
offer a easy to use frontend for the openssl console commands to create CAs,
sign and revoke certificates and also for some other tasks often needed
when managing CAs (see below: section "Use Cases"). Additionally, there are 
some scripts for customers of CAs for managing their digital identities (DIs) - 
for example for creating private keys or certificate signing requests.

The project is prepared for a full fledged 3-tier CA hierarchy:
* Root CA
* Intermediate CAs
* Issuing CAs

The project does explicitely *not* aim to support the "on behalf of" strategy
 when issuing certificates: Neither the CAs created with nor the scripts 
 provided by this projects will facilitate the creation of private keys 
  for end users.
  
We strictly endorse policies where the CA never even sees a private key of an end user,
let alone create those.

## Content
This project consists of Linux shell scripts - some of them are meant to be run from inside 
 the terminal by the user, some of them exist to be called from other
 scripts. Additionally, there is also a number of expect scripts:
 
### Linux scripts for the user
<dl>
  <dt>create_ca.sh</dt>
  <dd>This script lets the user create a CA. It asks for the kind of CA
  (Root, Intermediate, ...) and some configuration options. Then, it builds
  a directory structure and populates it with the necessary files.
  Finally, a certificate signing request (CSR) is created</dd>
  <dt>install_ca_certificate.sh</dt>
  <dd>This script takes the certificate produced by the certificate authority
  for the new CA and installs it in the correct place inside the directory structure.</dd>
  <dt>manage_certs.sh</dt>
  <dd>This script lists all certificates ever issued by this CA and their 
  current state or - if a date is given - all valid certificates with 
  an end date of their validity befor this given date.</dd>
  <dt>reneq_cert_req.sh</dt>
  <dd>This script issues a CSR for renewal of a soon to be expiring certificate:
  If the private key should stay the same - thats the option to choose!</dd>
  <dt>request_certificate.sh</dt>
  <dd>This script is for end users: They can use it in conjunction with
  configuration files provided by the CA to request a certificate. It creates
  the appropriate CSR from a private key provided by the user. If she has none, the
  private key can be generated as well.</dd>
  <dt>revoke_crl.sh</dt>
  <dd>This script shows all currently valid certificates. The user 
  can choose one of them. This is then revoked and the certificate revocation list 
  (CRL) is also updated accordingly.</dd>
  <dt>sign_request.sh</dt>
  <dd>This script takes a CSR and creates a certificate for it after
  presenting the CSR to the user in a human-readable form and asking
  for confirmation.</dd>
</dl>

### Linux helper scripts
<dl>
  <dt>configure_gui.sh</dt>
  <dd></dd>
</dl>

### Expect scripts
These scripts are needed to hide the complexities of calling and interacting with the openssl 
command line program. They automate the interactive process when using the openssl
executable to manipulate components of the PKI
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

## Use Cases

### Building a new Certificate Authority
Building an new CA is done in several steps:
* laying down the policy of the ca
* creation of a private key for the CA
* creation of the infrastructure of the CA (directory structure, serial number, database,...)
* creation of the basic configuration files of the ca
* creation of a certificate signing request and shipping it to a ca for signing
* installation of the certificate and thus commencing normal operation

### Signing Certificate Signing Requests
Signing certificate signing requests is done by using the script `sign_request.sh`.
It needs the CSR of course as well as the private key of the CA itself.
The user has to specify the password protecting the CAs private key.
Additionally, the user has to decide, what kind of certificate he wants to issue: 
For example the identity CA configuration allows to issue
* Encryption
* Identity and
* S/Mime 
certificates.

The certificate is then packaged with additional files into a ZIP-Archive
ready to be shipped to the end-user.

### Revoking Certificates
The revocation is done by receiving information about the party whose
certificate should be invalidated. Once the script `revoke_crl.sh` is started,
a scrollable list of all valid certificates is displayed. The user selects 
the one matching the request and is then asked for confirmation. If he 
gives it, the revocation is executed and the CRL of the CA updated

### Managing Certificate Lifecycle

### Requesting Certificates
