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
