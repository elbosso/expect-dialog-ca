## Some useful OpenSSL commands

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

#### Dumpo Certificates PEM encoded
```
openssl s_client -showcerts -connect www.example.com:443
```

### STARTTLS
```
openssl s_client -showcerts -starttls imap -connect mail.domain.com:139
```

### Raw

#### See the raw structure of an ASN.1 file (only for DER encoded files)

openssl asn1parse -in mysterious_file.pem

## Some resources with useful OpenSSL commands

* [OpenSSL command cheatsheet](https://www.freecodecamp.org/news/openssl-command-cheatsheet-b441be1e8c4a/)
* [21 OpenSSL Examples to Help You in Real-World](https://geekflare.com/openssl-commands-certificates/)
* [The Most Common OpenSSL Commands](https://www.sslshopper.com/article-most-common-openssl-commands.html)
* [OpenSSL Quick Reference Guide](https://www.digicert.com/ssl-support/openssl-quick-reference-guide.htm)
* [openssl_commands.md](https://gist.github.com/webtobesocial/5313b0d7abc25e06c2d78f8b767d4bc3)
* [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs)
* [OpenSSL tips and tricks](https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art030)
* [Checking A Remote Certificate Chain With OpenSSL ](https://langui.sh/2009/03/14/checking-a-remote-certificate-chain-with-openssl/)
