## How to build an actual PKI from all this?

### Root CA

First lets assume you cloned the repository (or checked it out or exported it - whatever floats your boat).
We assume that you start your journey inside this directory - to make
sure we are on the same page (or in
the same directory - so to speak) this is the directory holding -
among others - the script `create_ca.sh`.
The first thing to do then is to create a root CA.
For this you need to call the script

`create_ca.sh`

Then the script takes you by the hand and asks you a few questions. When it asks,
what kind of CA you want to create - choose root CA. Only two things are important
here (and from here on):

1. When you choose a file make sure it is actually selected (its full name appears 
in the field below the two boxes showing directories and files) - mere highlighting
 the file inside those boxes doesnt count!
2. Dont name the CA simply "root" - that confuses the scripts and does not bode well...

When the script is successful, you get a directory named <whatever you called your CA>
inside the directory you started the script `create_ca.sh` in. Additionally,
there will be a file named <whatever you called your root CA>-ca.csr - the signing request.
 
Now cd into the directory of the ca:
 
`cd  <whatever you called your root CA>`

and start signing its signing request:

`../sign_request.sh`

During the execution of this script it asks what kind of certificate you
want to issue and shows you a menu with the available choices. Because
we are currently self-signing, you have to choose root at this point.

When this is done - remember what was said earlier about selecting files? - 
a file is created inside the directory you are currently in called deliverables_<whatever you choose as CN for your root CA>.zip.
Now - without leaving the directory, you install the certificate inside
the CA directory structure by executing the script

`../install_ca_certificate.sh`

This - among other things - creates your first CRL and stores the certificate in
the appropriate place.

### Intermediary CA

Tired yet? If not - lets create another CA - this time it will be one 
not fit for issuing end entity certificates but acting as parent for CAs 
issuing actual end user certificates. For that, we go up one level in the
directory structure:

`cd ..`

Now we start over by executing the script for CA creation again:

`create_ca.sh`

Now we dont chose a root CA but an intermediate CA as its type.
You may be confused because there is no "intermediate" to choose.
The reason for this: it is called network CA here. So lets
create a network CA next - and always remember:
you must not name it after its type - so as was the name root when creating the root CA,
this time the name intermediate is forbidden!

After the script completed successfully, another CSR has been created along with a directory
holding all the files that make up our new CA. This time we do not
change directory into this new CAs home dir: We change into the directory
holding the root ca:

`cd  <whatever you called your root CA>`

and start signing its signing request:

`../sign_request.sh`

Again - choose the right kind of certificate to be issued - this time,
that will be intermediate.
When this is done, a file named
deliverables_<whatever you choose as CN for your intermediate CA>.zip.
is created. Now you have to change directory into the directory that holds
your newly created intermediate CA:

`cd  ../<whatever you called your intermediate CA>`

Now, you install the certificate inside
the CA directory structure by executing the script

`../install_ca_certificate.sh`

This - among other things - creates your first CRL and stores the certificate in
the appropriate place.

### Signing CA (Identity)

Now we have a CA that acts as authority for other CAs that are actually able 
to issue end user certificates. We need to create some of those. First, lets start 
with an identity CA - for this, we first need to change back to our
top-level directory

`cd ..`

and start by creating another CA:

`create_ca.sh`

Now we chose yet a different kind of CA - namely an identity CA.
So lets
create such a CA next - and always remember:
you must not name it after its type - so as was the name root when creating the root CA,
this time the name identity is forbidden!

One new aspect comes into play here: The script lets you specify
default values for the different kinds of certificates it can 
issue. Later, when the PKI is finished you may want to give the
configuration files to prospective customers that are a result
of the execution of this script. They reside in
`<whatever you called your identity CA>`. The default values you
gave when creating the identity CA are merged into those 
config files and when someone builds a certificate request using 
one of them, she sees them and can just click through the
tedious process of entering data - if the defaults suit her
of course.

After the script completed successfully, another CSR has been created along with a directory
holding all the files that make up our new CA. This time we do not
change directory into the root CAs home dir: We change into the directory
holding the intermediate ca:

`cd  <whatever you called your intermediate CA>`

and start signing its signing request:

`../sign_request.sh`

Again - choose the right kind of certificate to be issued - this time,
that will be identity.
When this is done, a file named
deliverables_<whatever you choose as CN for your identity CA>.zip.
is created. Now you have to change directory into the directory that holds
your newly created identity CA:

`cd  ../<whatever you called your intermediate CA>`

Now, you install the certificate inside
the CA directory structure by executing the script

`../install_ca_certificate.sh`

This - among other things - creates your first CRL and stores the certificate in
the appropriate place.

### Signing CA (Components)

Now that we have success fully established our first CA for
issuing end entity certificates, lets do this again - 
after all: it was fun right?
So now we create another kind of those: this time it will be
a component CA - for this, we first need to change back to our
top-level directory

`cd ..`

and start by creating another CA:

`create_ca.sh`

Now we chose yet a different kind of CA - namely a component CA.
So lets
create such a CA next - and always remember:
you must not name it after its type - so as was the name root when creating the root CA,
this time the name component is forbidden!

As with the identity CA, the script lets you specify
default values for the different kinds of certificates it can 
issue - and for the same reasons. 

After the script completed successfully, another CSR has been created along with a directory
holding all the files that make up our new CA. This time we do not
change directory into the root CAs home dir: We change into the directory
holding the intermediate ca:

`cd  <whatever you called your intermediate CA>`

and start signing its signing request:

`../sign_request.sh`

Again - choose the right kind of certificate to be issued - this time,
that will be identity.
When this is done, a file named
deliverables_<whatever you choose as CN for your identity CA>.zip.
is created. Now you have to change directory into the directory that holds
your newly created identity CA:

`cd  ../<whatever you called your intermediate CA>`

Now, you install the certificate inside
the CA directory structure by executing the script

`../install_ca_certificate.sh`

This - among other things - creates your first CRL and stores the certificate in
the appropriate place.

## How to operate an actual Issuing CA

Remember when there was a sentence that said that building a CA
also made sure that convenient OpenSSL configuration files were
created? If not, now is the time to pay those files some attention:

The directory called etc inside the CAs folder structure holds various
config files: one that is responsible for operating the CA and several others
useful for clients wanting a signature from this CA. For example: if
you had a component CA set up named issuecomp - that is one that for example
issues TLS server certificates or code signing certificates and so on - 
the contents of folder etc would look soewhat like this:

 * issuecomp-ca.conf
 * client.conf
 * ocspsign.conf
 * server.conf
 * timestamp.conf
 
The one that is named <whatever name the ca has>-ca.conf is
the configuration used when you actually operate the CA - for
example issuing or revoking certificates. The other configuration files
are for your prospective customers - so if someone wants to 
request a signature on his or her private key of a new TLS
server - you give him or her the server.conf file. Then - using
this configuration - a certificate request is created and sent
for you to sign it.

This holds for all CA types this PKI structure offers. If you read 
the section about creating the PKI hierarchy again, you can see this already
working when requesting and issuing the intermediary CA certificates.

One important thing needs to be mentioned however: the configuration 
for the TLS server certificates slightly differ from all the others
in one important aspect: Other than the others, it does not suffice
to just call OpenSSL with the config and be done with it:

Because a TLS server may have many different names and the certificate has
to be issued for all of them, these names must be specified by an
environment variable that must be set prior to calling OpenSSL
for creating the certificate request. The name of this
environment variable is SAN.

Further information about this specific scenario can be found for example here:

 * https://sys4.de/de/blog/2014/05/24/einen-tlsa-record-fuer-dane-mit-bind-9-publizieren/
 * https://blog.pki.dfn.de/2015/12/openssl-csr-fuer-ein-ssl-server-zertifikat-mit-mehreren-host-namen-erzeugen/
 