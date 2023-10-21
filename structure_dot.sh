#!/bin/bash
certs=$(find . -type f -path '*certs*/*' -name '*.crt' ! -path '*trash*/*' ! -path '*revoked*/*')

#Set the field separator to new line
IFS=$'\n'

echo "digraph D{">graphviz.dot

echo "subgraph cluster_testing{label=\"Tests\"">>graphviz.dot
for cert in ${certs}
do
  echo "$cert"
  openssl x509 -noout -text -in "$cert"|grep "CA:TRUE" >/dev/null
  if [ $? -eq 0 ]; then
#    echo "found: $cert"
    subject=$(openssl x509 -noout -subject -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"TEST"* && ! $sdnu == *"INDEPENDENT"* ]]; then
      startdate=$(openssl x509 -noout -startdate -in "${cert}"|cut -d '=' -f 2)
      enddate=$(openssl x509 -noout -enddate -in "${cert}"|cut -d '=' -f 2)
      #echo "${subject} [shape=box label=\"$sdn\lexpires on: $enddate\"]">>graphviz.dot
      echo "${subject} [shape=box label=<$sdn<br align=\"left\"/><font point-size=\"8\">From: $startdate<br/>To: $enddate</font>>]">>graphviz.dot
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
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"TEST"* && $sdnu == *"INDEPENDENT"* ]]; then
      echo "${subject} [shape=box label=<$sdn<br align=\"left\"/><font point-size=\"8\">From: $startdate<br/>To: $enddate</font>>]">>graphviz.dot
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
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ $sdnu == *"EXT PARTY"* || $sdnu == *"EXTERNAL PARTY"* ]]; then
      echo "${subject} [shape=box label=<$sdn<br align=\"left\"/><font point-size=\"8\">From: $startdate<br/>To: $enddate</font>>]">>graphviz.dot
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
    sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    sdnu=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p'| tr '[:lower:]' '[:upper:]')
    if [[ ! $sdnu == *"EXTERNAL PARTY"* && ! $sdnu == *"EXT PARTY"* && ! $sdnu == *"TEST"* ]]; then
      echo "${subject} [shape=box label=<$sdn<br align=\"left\"/><font point-size=\"8\">From: $startdate<br/>To: $enddate</font>>]">>graphviz.dot
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
    issuer=$(openssl x509 -noout -issuer -in "${cert}"|cut -d '=' -f 2-| sed 's/[\*\.\" ,=-]//g')
    #sdn=$(openssl x509 -noout -subject -in "${cert}"| sed -n '/^subject/s/^.*CN\s*=\s*//p')
    echo "$issuer -> ${subject}">>graphviz.dot
  fi

done

echo "}">>graphviz.dot