## Some useful OpenSSL commands

[[_TOC_]]

### Private Key

#### Print out the private key details

```
openssl rsa -check -text -in privateKey.key
```

#### Print out the hashes of the private key

```
openssl rsa -noout -modulus -in privateKey.key | openssl md5
openssl rsa -noout -modulus -in privateKey.key | openssl sha1
openssl rsa -noout -modulus -in privateKey.key | openssl sha256
openssl rsa -noout -modulus -in privateKey.key | openssl sha512
```

#### Change password

```
openssl rsa -aes256 -in privateKey.key -out newPrivateKey.key
```

### Certificate

#### Print out the hashes of the certificate

```
openssl x509 -noout -modulus -in certificate.crt | openssl md5
openssl x509 -noout -modulus -in certificate.crt | openssl sha1
openssl x509 -noout -modulus -in certificate.crt | openssl sha256
openssl x509 -noout -modulus -in certificate.crt | openssl sha512
```

Or, alternatively:

```
openssl x509 -noout -fingerprint -in certificate.crt
openssl x509 -noout -fingerprint -sha256 -in certificate.crt
```

#### Print out the content of the certificates

```
openssl x509 -in certificate.crt -noout -text|more
```

#### Print out specific fields of the certificates 

```
openssl x509 -noout -subject certificate.crt
openssl x509 -noout -issuer certificate.crt
openssl x509 -noout -dates certificate.crt
```

#### Inspect server certificates

```
echo | openssl s_client -servername www.openssl.org -connect www.openssl.org:443 2>/dev/null | openssl x509 -noout -text|more
echo | openssl s_client -servername imap.arcor.de -connect imap.arcor.de:993 2>/dev/null | openssl x509 -noout -text|more
```

### S/Mime

#### create signature

```
openssl smime -sign -in msg.txt -text -out msg.p7s -signer certificate.crt -inkey privateKey.key
```


#### Verify signature

```
openssl smime -verify -in msg.p7s -CAfile chain.pem
```


### CRL

#### Print out the contents of the CRL

```
openssl crl -inform DER -noout -text  -in crl/cacrl.der
openssl crl -inform PEM -noout -text  -in crl/cacrl.pem
```

### PKCS#12

#### Display contents

```
openssl pkcs12 -info -in  digitalIdentity.p12
```

#### Create from certificate and private key 

```
openssl pkcs12 -export -in certificate.cert -inkey privateKey.key -out digitalIdentity.p12
```

#### Extract private key

```
openssl pkcs12 -in digitalIdentity.p12 -out privateKey.key
```

#### Convert to PEM

```
openssl pkcs12 -in digitalIdentity.p12 -out digitalIdentity.pem 
```

### TSA

#### Display query

```
openssl ts -query -in query.tsq -text
```

#### Display reply

```
openssl ts -reply -in reply.tsr -text
```

#### Verify reply

```
openssl ts -verify -in reply.tsr -data data.dat -CAfile chain.pem
```

#### Extract token from reply

```
openssl ts -reply -in reply.tsr -token_out -out token.tk
```

#### Extract certificates from token

```
openssl pkcs7 -inform DER -in token.tk -print_certs -noout -text
```

### CSR

#### Create from existing key

```
openssl req -new -key privateKey.key -out my.csr
```

#### Display

```
openssl req -in my.csr -noout -text
```

### HTTPS

#### Dump Certificates PEM encoded
```
openssl s_client -showcerts -connect www.example.com:443
```

### STARTTLS

#### Dump Certificates PEM encoded
```
openssl s_client -showcerts -starttls imap -connect mail.domain.com:139
```

### S/MIME verification

#### Possible outcomes

Message was tampered with (return code 4):

```
Verification failure
140485684135232:error:2E09A09E:CMS routines:CMS_SignerInfo_verify_content:verification failure:../crypto/cms/cms_sd.c:847:
140485684135232:error:2E09D06D:CMS routines:CMS_verify:content verify error:../crypto/cms/cms_smime.c:393:
```

Message signature not trusted (return code 4):

```
Verification failure
140146111432000:error:2E099064:CMS routines:cms_signerinfo_verify_cert:certificate verify error:../crypto/cms/cms_smime.c:252:Verify error:unable to get local issuer certificate
```

Message not signed (return code 2):

```
Error reading S/MIME message
140701208487232:error:0D0D40CD:asn1 encoding routines:SMIME_read_ASN1:invalid mime type:../crypto/asn1/asn_mime.c:469:type: multipart/alternative
```

Validation successful (return code 0):

```
Verification successful
```

#### Verify the validity of an email message

```
openssl cms -verify -in some_email_message.eml
```

#### Verify the validity of an email message explicitly specifying trust

```
openssl cms -verify -in some_email_message -CAfile trust_anchor-crt
```

#### Signed and encrypted messages need to be decrypted first:

Note: the P12 file holding the digital identity must be pem-encoded! (see above)

```
openssl cms -decrypt -out decrypted_email_message  -inkey p12.pem -in some_encrypted_email_message
```

### Raw

#### See the raw structure of an ASN.1 file (only for DER encoded files)

```
openssl asn1parse -in mysterious_file.pem
```

## Some resources with useful OpenSSL commands

* [OpenSSL command cheatsheet](https://www.freecodecamp.org/news/openssl-command-cheatsheet-b441be1e8c4a/)
* [21 OpenSSL Examples to Help You in Real-World](https://geekflare.com/openssl-commands-certificates/)
* [The Most Common OpenSSL Commands](https://www.sslshopper.com/article-most-common-openssl-commands.html)
* [OpenSSL Quick Reference Guide](https://www.digicert.com/ssl-support/openssl-quick-reference-guide.htm)
* [openssl_commands.md](https://gist.github.com/webtobesocial/5313b0d7abc25e06c2d78f8b767d4bc3)
* [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs)
* [OpenSSL tips and tricks](https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art030)
* [Checking A Remote Certificate Chain With OpenSSL ](https://langui.sh/2009/03/14/checking-a-remote-certificate-chain-with-openssl/)
* [OpenSSL: how to extract certificates and token status from RFC3161 timestamping reply?](https://stackoverflow.com/questions/66044640/openssl-how-to-extract-certificates-and-token-status-from-rfc3161-timestamping)
