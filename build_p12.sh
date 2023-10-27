#!/bin/sh

if [ $# -lt 1 ];then
	echo "you must specify the file containing your private key! (https://elbosso.github.io/expect-dialog-ca/)"
	exit 1;
fi
if [ ! -e ./tmp ];then
	mkdir ./tmp
fi
cns=`grep Subject: issuer.crt |sed -E "s/(.*?)CN=(.*?)/\2/g"`
echo "$cns"
. ../index.txt
echo "$zert"
scn=$(grep Subject: "../$zert" |sed -E "s/(.*?)CN=(.*?)/\2/g")
echo "$scn"
stmta="openssl pkcs12 -export -name \"$scn\" "
while IFS= read -r line
do
 stmta="$stmta -caname \"$line\" "
done < <(printf '%s\n' "$cns")
stmta="${stmta} -inkey \"$1\" -in \"../$zert\" -certfile issuer.crt -out \"${scn}.p12\""
echo "$stmta"
eval $stmta
echo "P12 file \"`readlink -f ${scn}.p12`\" created"
