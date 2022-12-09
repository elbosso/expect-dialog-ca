#!/bin/bash
certs=$(find . -type f -path '*certs*/*' -name '*.crt' ! -path '*trash*/*' ! -path '*revoked*/*')

#Set the field separator to new line
IFS=$'\n'

revokeds=$(cat Dama11_Intermediary_Test_CA/ca/db/Dama11_Intermediary_Test_CA-ca.db|grep "^R"|cut -f 6-,4|sed 's+\t/+_+g')

#for revoked in ${revokeds}
#do
#  echo "$revoked"
#done

echo "digraph D{">graphviz.dot

echo "subgraph cluster_testing{label=\"Tests\"">>graphviz.dot
for cert in ${certs}
do
  echo "$cert"
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    s=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-|sed 's/ = /=/g'|sed 's+, +/+g')
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"TEST"* && ! $sdnu == *"INDEPENDENT"* ]]; then
    issdn=$(openssl x509 -noout -issuer -in "${cert}"| sed -n '/^issuer/s/^.*CN\s*=\s*//p')
    serial=$(openssl x509 -noout -serial -in "${cert}"|cut -d'=' -f2)
#    echo "subject: $subject"
#    echo "issuer: $issuer"
    echo $revokeds | grep -q "${serial}_$s"
#    if [ ! $? -eq 0 ]; then
      echo "${subject} [shape=box label=\"$sdn\"]">>graphviz.dot
#    fi
    fi
  fi
done
echo "subgraph cluster_independent{label=\"Independent Hierarchy\"">>graphviz.dot
for cert in ${certs}
do
  echo "$cert"
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    s=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-|sed 's/ = /=/g'|sed 's+, +/+g')
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"TEST"* && $sdnu == *"INDEPENDENT"* ]]; then
    issdn=$(openssl x509 -noout -issuer -in "${cert}"| sed -n '/^issuer/s/^.*CN\s*=\s*//p')
    serial=$(openssl x509 -noout -serial -in "${cert}"|cut -d'=' -f2)
#    echo "subject: $subject"
#    echo "issuer: $issuer"
    echo $revokeds | grep -q "${serial}_$s"
#    if [ ! $? -eq 0 ]; then
      echo "${subject} [shape=box label=\"$sdn\"]">>graphviz.dot
#    fi
    fi
  fi
done
echo "}">>graphviz.dot
echo "}">>graphviz.dot

echo "subgraph cluster_external{label=\"External Hierarchies\"">>graphviz.dot
for cert in ${certs}
do
  echo "$cert"
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    s=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-|sed 's/ = /=/g'|sed 's+, +/+g')
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"EXT PARTY"* || $sdnu == *"EXTERNAL PARTY"* ]]; then
    issdn=$(openssl x509 -noout -issuer -in "${cert}"| sed -n '/^issuer/s/^.*CN\s*=\s*//p')
    serial=$(openssl x509 -noout -serial -in "${cert}"|cut -d'=' -f2)
#    echo "subject: $subject"
#    echo "issuer: $issuer"
    echo $revokeds | grep -q "${serial}_$s"
#    if [ ! $? -eq 0 ]; then
      echo "${subject} [shape=box label=\"$sdn\"]">>graphviz.dot
#    fi
    fi
  fi
done
echo "}">>graphviz.dot

echo "subgraph cluster_production{label=\"Production\"">>graphviz.dot
for cert in ${certs}
do
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    s=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-|sed 's/ = /=/g'|sed 's+, +/+g')
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ ! $sdnu == *"EXTERNAL PARTY"* && ! $sdnu == *"EXT PARTY"* && ! $sdnu == *"TEST"* ]]; then
    issdn=$(openssl x509 -noout -issuer -in "${cert}"| sed -n '/^issuer/s/^.*CN\s*=\s*//p')
    serial=$(openssl x509 -noout -serial -in "${cert}"|cut -d'=' -f2)
#    echo "subject: $subject"
#    echo "issuer: $issuer"
    echo $revokeds | grep -q "${serial}_$s"
#    if [ ! $? -eq 0 ]; then
      echo "${subject} [shape=box label=\"$sdn\"]">>graphviz.dot
#    fi
    fi
  fi
done
echo "}">>graphviz.dot

for cert in ${certs}
do
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    s=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-|sed 's/ = /=/g'|sed 's+, +/+g')
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    issdn=$(openssl x509 -noout -issuer -in "${cert}"| sed -n '/^issuer/s/^.*CN\s*=\s*//p')
    serial=$(openssl x509 -noout -serial -in "${cert}"|cut -d'=' -f2)
#    echo "subject: $subject"
#    echo "issuer: $issuer"
#    echo "$s $serial"
    echo $revokeds | grep -q "${serial}_$s"
#    if [ ! $? -eq 0 ]; then
      echo "$issuer -> ${subject}">>graphviz.dot
#    else
#      echo "revoked: ${serial}_$s"
#    fi
  fi

done
#echo "$revokeds" | grep "C=DE/O=Damaschkestr. 11/OU=Arbeitszimmer/CN=test comp"

echo "}">>graphviz.dot