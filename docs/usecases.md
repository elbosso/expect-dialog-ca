## Use Cases

### Certificate Authorities

Here, the use cases for issuing Entities also known as 
certificate authorities are collected.

#### Building a new Certificate Authority
Building an new CA is done in several steps:
* laying down the policy of the ca
* creation of a private key for the CA
* creation of the infrastructure of the CA (directory structure, serial number, database,...)
* creation of the basic configuration files of the ca
* creation of a certificate signing request and shipping it to a ca for signing
* installation of the certificate and thus commencing normal operation

This process is rather lengthy and there are several scripts involved: After
the policy is written down, you should have all information for customizing the 
CA about to be created. Now, you need to use [create_ca.sh](../create_ca.sh). This script
guides you through all the steps needed for 
* creation of a private key for the CA
* creation of the infrastructure of the CA (directory structure, serial number, database,...)
* creation of the basic configuration files of the ca
* creation of a certificate signing request and shipping it to a ca for signing
The user has to answer quite a lot of questions - for example key length
for the private key (if none is provided), the Hash or Signing algorithmus
to be used as part of the Message Authentication Code (MAC) among others.

The script offers an optional way to specify some of the information the user
has to enter during this process beforehand - by writing an ini file named _ca_presets.ini_.
This file has to reside in the current directory. Its format is `key="value"`. The double quotes can be
omitted if the value does not contain spaces. Allowed keys at this time are:

* countryName
  used for the subject data and for the default values for config items
  in end user configs (see below)
* organizationName
  used for the subject data and for the default values for config items
  in end user configs (see below)
* organizationalUnitName
  used for the subject data and for the default values for config items
  in end user configs (see below)
* commonName
  used for the subject data
* base_url
  used for the configuration of the CA - everywhere where an URL is needed;
  for example location of CA certificate, CRL,...
* stateOrProvinceName
  used in end user configs (see below)
* localityName
  used in end user configs (see below)

Additionally, the script lets the user specify default values for config
file items - especially when creating an issuing CA: Maybe you
want to save your end users the hustle having to specify Country and 
Locality? Then here is your chance: Just define defaults and your end users
can just click through those annoying questions!
Another thing is the (optional) provision of Certificate Policy Statements:
For each config of the CA you can specify them - so they
get incorporated into every certificate you create using the 
corresponding configuration. And last but not least: The script
offers you the (optional) means to define additional OIDs:
If you use custom OIDs (for example for specifying custom policies),
application will display them as unintuitive sequences of numbers separated
by dots - unless you take the time to  define them: then a mapping is
included into each issued certificate that allows applications
to display a descriptive text instead of the numeric OID.

After the script is done, you have a fully populated directory structure
for your CA as well as a CSR you need to get signed by another CA. When this is done,
you get a certificate back ready for installation. The script [install_ca_certificate.sh](../install_ca_certificate.sh)
helps with that: it
* installs of the certificate,
* creates the initial CRL and
* creates the certificate chain in PEM-format.
Now, you can start to use this CA for issuing certificates

#### Renewal of a certificate of a Certificate Authority
A certificate authority needs a private key an a valid certificate to
operate. Certificates however always have an expiration date. So every
certficate authority gets sooner or later to a point in time where 
 the certificate needs to be renewed.
 
For certificate authorities it is crucial that the digital identity 
 does not change when it gets a new certificate. This is only possible
 if the private key does not change. 
 
The project supports this use case by means of the script
[reneq_cert_req.sh](../reneq_cert_req.sh): It constructs a Certificate signing request from
an existing private key and certificate to be signed by the certificate 
authority that signed the soon-to-be-expiring certificate.

### Changing the Password for the Private Key of a Certificate Authority
At the first glance many people might think that there should never be 
a need for this use case - however: When an authorized operator of the
certificate authority gets her privileges removed, she must not be
able to act on behalf of the certificate authority. If the key is
not on some kind of hardware token management could withdraw, the password
needs to be changed - and this is where the script [change_ca_password.sh](../change_ca_password.sh)
comes into play. 

It asks for the current password and for the new password. It then backs up the old
key file and secures the key using the given password and aes256. The
new key is written back into a file with the original name. After checking that the 
key file works - the backup file must be immediately destroyed!!

#### Responding to Certificate Signing Requests
Responding to certificate signing requests is done by using the script [sign_request.sh](../sign_request.sh).
A Certificate signing request essentially asks a certificate authority to
certify the association between a certain private key and whatever 
claims the CSR holds (canonical name, server adresses, email adresses and so on).
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

#### Revoking Certificates
The revocation is done by receiving information about the party whose
certificate should be invalidated. Once the script [revoke_crl.sh](../revoke_crl.sh) is started,
a scrollable list of all valid certificates is displayed. The user selects 
the one matching the request and is then asked for confirmation. If he 
gives it, the revocation is executed and the CRL of the CA updated.

However, attention is required from the administrator or operator of the certificate
authority: Depending on the policies implemented, it is the duty
of the operator to ascertain that the entity that made the request is 
actually the rightful owner and therefore permitted to actually do so.
This can be done for example by checking the Fingerprint of the private
key obtained from the requestor with the fingerprint of the certificate to be revoked.
The equality alone is *-one can not stress this enough-* however depending
 on the policy not sufficient to actually revoke the certificate in question.

#### Keeping the CRLs valid
The validity period of a certificate revocation list is always 
   limited. The PKI or CA is responsible for refreshing the CRL before
   the validity of the last one is up. The script [refresh_crl.sh](../refresh_crl.sh)offers
   a convenient method of doing so.

#### Managing Certificate Lifecycle
It is crucial for a well-managed CA to watch out for certificates about
to reach their end-of-validity date. If this is monitored closely, one
can remember the end users of the impending end of the certificates validity
and remind them of applying for a renewal. 

For this, the script [reneq_cert_req.sh](../reneq_cert_req.sh) was made: The end user can
use it to create a new CSR using his private key. He can send this new CSR to the 
CA and get his certificate renewed.

To get information about certificates soon to become invalid,
the script [manage_certs.sh](../manage_certs.sh) is used: The user can choose a certain day and the 
script presents a list with certificates expiring before that date. This
makes it possible for example to get a list of all certificates expiring 
within the next two months.

### Non-issuing Entities

Here, all use cases for Subjects are collected that do not issue 
 certificates themselves but use them for a variety of possible uses (
 establishing the identity of a web server or email sender for example
 ). Those uses are not in the scop of this project and neither of this document.
  
#### Requesting Certificates
To apply for a certificate, the script [request_certificate.sh](../request_certificate.sh) is used: 
The end user has to give his
private key and the password for unlocking it as well as 
the name of the file the new CSR is to be saved into. 
An important additional
parameter is the kind of certificate he wishes to obtain - the identity CA for example
is able to issue the following flavours:
* Encryption
* Identity and
* S/Mime 

#### Renewal of Certificates
If the end user already has a certificate and only wants to renew it without
also creating a new private key, the script [request_certificate_renewal.sh](../request_certificate_renewal.sh) supports
this: The user has to provide her private key and the soon-to-be-expired certificate.
The resulting CSR can then be sent to the certificate authority that
acted as issuer for the old certificate for renewal.

This method has the benefit of not changing the digital identity of the subject by
 keeping the private key.

#### Revocation request 
A nin-issuing entity needs to check that their private key is not compromised.
If it is, it should request that the issuing certificate authority revokes the
associated certificate. How exactly this request is made depends strongly
on the policies implemented by the certificate authority in question and for this reason,
no script is contained in this project to address this particular
use case.
