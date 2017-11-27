## Special kinds of CAs (special deliverables)

There are - from a trust chain point of view - three different kinds of CAs that can be 
managed with the materials contained in this project:
1. Root CAs - CAs self signing their keys and therefore the
root of any trust chain
2. Intermediate CAs - CAs that do not issue end entity certificates but
rather create certificates for other CAs (Root CAs are a
special case of intermediate CAs)
3. Issuing CAs - CAs issuing end entity certificates - such CAs will never
create certificates for other CAs.

The Issuing CAs themselves can be categorized by the kind of vertificates they issue:
1. Digital Identities - Certificates that play a role in ascertaining
the identity of another party. Examples include TLS Client and Server
certificates as well as certificates used when cryptographically 
securing email communications. And of course - having
a valid and trusted Digital Identity is also a key part
in acting as a CA.
2. Technical certificates - Certificates used to provide a kind of service.
This would for example include signing code, creating cryptographically 
secured time stamps or answering Online Certificate Status Protocol (OCSP)-queries.

All of those use cases for certificates have slightly different demands:
To use certificates for Digital Identities - one is often tasked with
providing a PKCS#12 container rather than the naked certificate and private key
for example.

This project does not simply create a certificate and then spews it
back at the requestor - it builds an archive containing the certificate
but along with other useful things - namely
* the certificate in DER and PEM format and
* the complete certificate chain holding the certificates
of the issuing CA, every intermediate Ca up to and including the 
certificate of the root CA.

### Digital Identities

But it goes further: This project addresses special needs
for different kinds of certificates: All certificates issued to be used 
for Digital Identity Uses containn a (Bash) shell script for
converting the certificate and the private key belonging to it 
into a PKCS#12 container.

### Timestamp authorities

The deliverable for a TSA certificate request holds a config file
that includes information about how to request a cryptographic time stamp 
as well as information about creating one and verifying it. 
It is the foundation for creating a cryptographic time stamp using 
the certificate contained in the deliverables archive using OpenSSL.

### OCSP 

The specific content for the deliverable archive for OCSP certificates
is currently being discussed.

### Code Signing

The specific content for the deliverable archive for OCSP certificates
is currently being discussed.