## Some useful OpenSSL commands
<dl>
<dt>Print out the private key details</dt>
<dd>openssl rsa -check -text -in privateKey.key</dd>
<dt>Print out the hashes of the private key</dt>
<dd><ul>
<li>openssl rsa -noout -modulus -in privateKey.key | openssl md5</li>
<li>openssl rsa -noout -modulus -in privateKey.key | openssl sha1</li>
<li>openssl rsa -noout -modulus -in privateKey.key | openssl sha256</li>
<li>openssl rsa -noout -modulus -in privateKey.key | openssl sha512</li>
</ul>
</dd>
<dt>Print out the hashes of the certificate</dt>
<dd><ul>
<li>openssl x509 -noout -modulus -in certificate.crt | openssl md5</li>
<li>openssl x509 -noout -modulus -in certificate.crt | openssl sha1</li>
<li>openssl x509 -noout -modulus -in certificate.crt | openssl sha256</li>
<li>openssl x509 -noout -modulus -in certificate.crt | openssl sha512</li>
</ul>
</dd>
<dt>Print out the contents of the CRL</dt>
<dd>
<ul>
<li>
openssl crl -inform DER -noout -text  -in crl/cacrl.der
</li>
<li>
openssl crl -inform PEM -noout -text  -in crl/cacrl.pem
</li>
</ul>
</dd>

</dl>

## Some resources with useful OpenSSL commands

* [OpenSSL command cheatsheet](https://www.freecodecamp.org/news/openssl-command-cheatsheet-b441be1e8c4a/)
* [21 OpenSSL Examples to Help You in Real-World](https://geekflare.com/openssl-commands-certificates/)
* [The Most Common OpenSSL Commands](https://www.sslshopper.com/article-most-common-openssl-commands.html)
* [OpenSSL Quick Reference Guide](https://www.digicert.com/ssl-support/openssl-quick-reference-guide.htm)
* [openssl_commands.md](https://gist.github.com/webtobesocial/5313b0d7abc25e06c2d78f8b767d4bc3)
* [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs)
