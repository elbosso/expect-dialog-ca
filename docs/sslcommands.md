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
</dl>