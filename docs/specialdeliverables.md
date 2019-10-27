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

The component CA actually provides a configuration file for 
requesting certificates for creating trusted timestamps. An entity
about wanting to become a Trusted Timestamping Authority (TSA) would call
openssl on the lines of

```shell script
openssl req -new -config <path_to_config>/timestamp.conf -out <some_path>/tsa.csr -keyout <some_other_path>/tsa.key
```

to create a certificate request. This can be sent to a component CA to
be signed.

With the deliverables unpacked and with the path to the private key file known
the TSA can start circulating its own config file that came as part of
the deliverables. So anyone can generate timestamping requests using it like
for eample so:

```shell script
openssl ts -query -config <deliverables_unpacked_path>/tsa.conf -cert -data <path>/<some_file> -no_nonce -out <request_path>/<request>.tsq
```

The request can be viewed using 

```shell script
openssl ts -config <deliverables_unpacked_path>/tsa.conf -query -in <request_path>/<request>.tsq -text
```

When the TSA receives such a request it can furnish a reply - and thus a trusted
timestamp by issuing

```shell script
openssl ts -reply -config <deliverables_unpacked_path>/tsa.conf -queryfile <request_path>/<request>.tsq -out <reply_path>/reply.tsr -inkey <some_other_path>/tsa.key
```

After receiving the trusted timestamp, it can be verified by simply issuing 

```shell script
openssl ts -verify -config <deliverables_unpacked_path>/tsa.conf -queryfile <request_path>/<request>.tsq -in <reply_path>/reply.tsr -CAfile <deliverables_unpacked_path>/chain.pem
```

One can inspect the content - and thus ascertain the exact time the timestamp was issued - 
by using the following command:

```shell script
openssl ts -config <deliverables_unpacked_path>/tsa.conf -reply -in <reply_path>/reply.tsr -text
```

### OCSP 

The specific content for the deliverable archive for OCSP certificates
is currently being discussed.

### Code Signing

The specific content for the deliverable archive for OCSP certificates
is currently being discussed.