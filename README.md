# expect-dialog-ca
This repository contains scripts meant to make managing an openssl ca less painful inside a terminal environment

## Scope

### Overview
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

### Types of CAs

#### Root CA
The root CA is the trust anchor inside our PKI hierarchy. It can issue certificates
for intermediate CAs
#### Intermediate CA
The intermediate CAs (or network CAs) are the link in the trust chain between the root CA and
our issuing CAs.
#### Issuing CAs
The issuing CAs are CAs that actually issue certificates for end users. Those
certificates are each meant for a certain purpose - depending of the configuration
of the CAs and - in part - of the actual CSRs:
<dl>
<dt>Identity CA issues certificates for</dt>
<dd>

* Encryption
* Identity and
* S/Mime 
</dd>
<dt>Component CA issues certificates for</dt>
<dd>

* client authentication
* server authentication
* OCSP signing (OCSP stands for online certificate status protocol)
* timestamp authorities
</dd>
</dl>

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

This process is rather lengthy and there are several scripts involved: After
the policy is written down, you should have all information for customizing the 
CA about to be created. Now, you need to use `create_ca.sh`. This script
guides you through all the steps needed for 
* creation of a private key for the CA
* creation of the infrastructure of the CA (directory structure, serial number, database,...)
* creation of the basic configuration files of the ca
* creation of a certificate signing request and shipping it to a ca for signing
The user has to answer quite a lot of questions - for example key length
for the private key (if none is provided), the Hash or Signing algorithmus
to be used as part of the Message Authentication Code (MAC) among others.

After the script is done, you have a fully populated directory structure
for your CA as well as a CSR you need to get signed by another CA. When this is done,
you get a certificate back ready for installation. The script `install_ca_certificate.sh`
helps with that: it
* installs of the certificate,
* creates the initial CRL and
* creates the certificate chain in PEM-format.
Now, you can start to use this CA for issuing certificates

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
It is crucial for a well-managed CA to watch out for certificates about
to reach their end-of-validity date. If this is monitored closely, one
can remember the end users of the impending end of the certificates validity
and remind them of applying for a renewal. 

For this, the script `reneq_cert_req.sh` was made: The end user can
use it to create a new CSR using his private key. He can send this new CSR to the 
CA and get his certificate renewed.

To get information about certificates soon to become invalid,
the script `manage_certs.sh` is used: The user can choose a certain day and the 
script presents a list with certificates expiring before that date. This
makes it possible for example to get a list of all certificates expiring 
within the next two months.

### Requesting Certificates
To apply for a certificate, the script `manage_certs.sh` is used: 
The end user has to give his
private key and the password for unlocking it as well as 
the name of the file the new CSR is to be saved into. 
An important additional
parameter is the kind of certificate he wishes to obtain - the identity CA for example
is able to issue the following flavours:
* Encryption
* Identity and
* S/Mime 

<!--
If the end user already has a certificate and only wants to renew it without
also creating a new private key, the script `reneq_cert_req.sh` supports
this: 
-->