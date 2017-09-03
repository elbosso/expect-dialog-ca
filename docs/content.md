## Content
This project consists of Linux shell scripts - some of them are meant to be run from inside 
 the terminal by the user, some of them exist to be called from other
 scripts. Additionally, there is also a number of expect scripts:
 
### Linux scripts for the user
* [change_ca_password.sh](../change_ca_password.sh)  
  This script changes the password for the private key of a certificate
  authority. The old private key is backed up prior to 
  creation of the new key with the new password.
* [create_ca.sh](../create_ca.sh)  
  This script lets the user create a CA. It asks for the kind of CA
  (Root, Intermediate, ...) and some configuration options. Then, it builds
  a directory structure and populates it with the necessary files.
  Finally, a certificate signing request (CSR) is created
* [install_ca_certificate.sh](../install_ca_certificate.sh)  
  This script takes the certificate produced by the certificate authority
  for the new CA and installs it in the correct place inside the directory structure.
* [manage_certs.sh](../manage_certs.sh)  
  This script lists all certificates ever issued by this CA and their 
  current state or - if a date is given - all valid certificates with 
  an end date of their validity befor this given date.
* [refresh_crl.sh](../refresh_crl.sh)  
  This script renews the Certificate Revocation List of the 
  current Certificate Authority: Inside crls there is always 
  information about the end of its validity. A crls validity period is always 
   limited. The PKI or CA is responsible for refreshing the CRL before
   the validity of the last one is up. This script offers
   a convenient method of doing so.
* [reneq_cert_req.sh](../reneq_cert_req.sh)  
  This script issues a CSR for renewal of a soon to be expiring certificate:
  If the private key should stay the same - thats the option to choose!
* [request_certificate.sh](../request_certificate.sh)  
  This script is for end users: They can use it in conjunction with
  configuration files provided by the CA to request a certificate. It creates
  the appropriate CSR from a private key provided by the user. If she has none, the
  private key can be generated as well.

  This script runs without a GUI so as to put as few dependencies and preconditions
  in the way of a user getting her certificate.
* [request_certificate_renewal.sh](../request_certificate_renewal.sh)  
  This script is for end users: They can use it to renew their certificate - meaning to
  extend the validity of an already obtained certificate from the same 
  certificate authority. To do so, the user must have her old certificate as well as
  her private key (and the password for unlocking it) available.
  
  This script runs without a GUI so as to put as few dependencies and preconditions
  in the way of a user getting her certificate.
* [revoke_crl.sh](../revoke_crl.sh)  
  This script shows all currently valid certificates. The user 
  can choose one of them. This is then revoked and the certificate revocation list 
  (CRL) is also updated accordingly.
* [sign_request.sh](../sign_request.sh)  
  This script takes a CSR and creates a certificate for it after
  presenting the CSR to the user in a human-readable form and asking
  for confirmation.
  
### Linux helper scripts
* [configure_gui.sh](../configure_gui.sh)  
  This script is sourced by all other scripts used on the issuer side of
  things. It sets some basic environment bariables needed in all the scripts
  and does some other supporting stuff too.
* [ask_for_password.sh](../ask_for_password.sh)  
  This script is sourced by all scripts needing the user to specify 
  a new secret pasword. It displays the usual "please give new password/please type it
  again to verify"-GUI and does basic verification:
  * are both fields non-empty
  * are password and password verification equal
  
### Expect scripts
These scripts are needed to hide the complexities of calling and interacting with the openssl 
command line program. They automate the interactive process when using the openssl
executable to manipulate components of the PKI
* [ca_csr.xpct](../ca_csr.xpct)
* [ca_csr_with_key.xpct](../ca_csr_with_key.xpct)
* [cange_ca_password.xpct](../cange_ca_password.xpct)
* [gen_crl.xpct](../gen_crl.xpct)
* [priv_key_fingerprint.xpct](../priv_key_fingerprint.xpct)
* [req_from_cert.xpct](../req_from_cert.xpct)
* [revoke_cert.xpct](../revoke_cert.xpct)
* [sign_csr.xpct](../sign_csr.xpct)
* [sign_csr_dry.xpct](../sign_csr_dry.xpct)

