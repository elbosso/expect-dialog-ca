#!/bin/bash
#this script can be used to convert binary Signed Certificate Timestamps 
#into a form that can then be integrated into certificates using OpenSSL
if [ $# -lt 1 ];then
        echo "you must specify the file containing the binary SCT!)"
        exit 1;
fi
sctlen=$(ls -l "$1" |cut -d ' ' -f 5)
sctlistlen=$(($sctlen + 2))
echo -n $(printf "%04x" $sctlistlen)>sctextvalue.txt
echo -n $(printf "%04x" $sctlen)>>sctextvalue.txt
hexdump -v -e '/1 "%02X"' "$1" >>sctextvalue.txt

