# expect-dialog-ca
This repository contains scripts meant to make managing a Public Key 
Infrastructure using openssl less painful inside a terminal environment.

<!---
[![start with why](https://img.shields.io/badge/start%20with-why%3F-brightgreen.svg?style=flat)](http://www.ted.com/talks/simon_sinek_how_great_leaders_inspire_action)
--->
[![GitHub release](https://img.shields.io/github/release/elbosso/expect-dialog-ca/all.svg?maxAge=1)](https://GitHub.com/elbosso/expect-dialog-ca/releases/)
[![GitHub tag](https://img.shields.io/github/tag/elbosso/expect-dialog-ca.svg)](https://GitHub.com/elbosso/expect-dialog-ca/tags/)
[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![GitHub license](https://img.shields.io/github/license/elbosso/expect-dialog-ca.svg)](https://github.com/elbosso/expect-dialog-ca/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/elbosso/expect-dialog-ca.svg)](https://GitHub.com/elbosso/expect-dialog-ca/issues/)
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/elbosso/expect-dialog-ca.svg)](https://GitHub.com/elbosso/expect-dialog-ca/issues?q=is%3Aissue+is%3Aclosed)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/elbosso/expect-dialog-ca/issues)
[![GitHub contributors](https://img.shields.io/github/contributors/elbosso/expect-dialog-ca.svg)](https://GitHub.com/elbosso/expect-dialog-ca/graphs/contributors/)
[![Github All Releases](https://img.shields.io/github/downloads/elbosso/expect-dialog-ca/total.svg)](https://github.com/elbosso/expect-dialog-ca)
[![Website elbosso.github.io](https://img.shields.io/website-up-down-green-red/https/elbosso.github.io.svg)](https://elbosso.github.io/)

![expectdialogca_logo](resources/images/expectdialogca_logo.png)

With the supplied tools, even complex PKIs similar to the one in this example can be managed
easily and effectively:

![](resources/images/graphviz.svg)

Scripts for automatic analysis of complex PKIs and helping in the documentation - for
example creating diagrams like the one above - are also included here.

---
**NOTE**

Please note that there is a restriction concerning common names (CN): They must not contain non-ascii characters and they also must not contain any special characters such as parentheses or quotes of any kind or umlaute for example
---
## Table of contents

* [Scope](docs/scope.md)
* [Content](docs/content.md)
* [Dependencies](docs/dependencies.md)
* [Use Cases](docs/usecases.md)
* [How to build an actual PKI from all this?](docs/buildpki.md)
* [How can i customize my CA?](docs/customizeca.md)
* [Special kinds of CAs (special deliverables)](docs/specialdeliverables.md)
* [Some useful OpenSSL commands](docs/sslcommands.md)

## Useful external links
* [ASN.1 JavaScript decoder](https://lapo.it/asn1js/#)
* [S/MIME Example Keys and Certificates](https://datatracker.ietf.org/doc/html/rfc9216)
  
