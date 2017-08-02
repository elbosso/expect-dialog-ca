## How to build an actual PKI from all this?

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

When this is done - remember what was said earlier about selecting files? - 
a file is created inside the directory you are currently in called deliverables_<whatever you choose as CN for your root CA>.zip.
Now - without leaving the directory, you install the certificate inside
the CA directory structure by executing the script

`../install_ca_certificate.sh`

This - among other things - creates your first CRL and stores the certificate in
the appropriate place.

Tired yet? If not - lets create another CA - this time it will be one 
not fit for issuing end entity certificates but acting as parent for CAs 
issuing actual end user certificates. For that, we go up one level in the
directory structure:

`cd ..`

Now we start over by executing the script for CA creation again:

`create_ca.sh`

Now we dont chose a root CA but an intermediate CA as its type but always remember:
you must not name it after its type - so as was the name root when creating the root CA,
this time the name intermediate is forbidden!

After the script completed successfully, another CSR has been created along with a directory
holding all the files that make up our new CA. This time we do not
change directory into this new CAs home dir: We change into the directory
holding the root ca:

`cd  <whatever you called your root CA>`

and start signing its signing request:

`../sign_request.sh`

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

Now we have a CA that acts as authority for other CAs that are actually able 
to issue end user certificates. We need to create some of those. First, lets start 
with an identity CA - for this, we first need to change back to our
top-level directory

`cd ..`

and start by creating another CA:

`create_ca.sh`

