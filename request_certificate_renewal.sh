#!/bin/sh
optionerror=0
script_dir=`dirname $0`
key_file_location=""
cert_file_location=""
csr_file_location=""
printHelp ()
{
echo "usage: $0 [-k <file name for key file>] [-c <file name of old certificate>] [-o <file name of resulting CSR>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo "-k <file name for key file>\tIf this file exists, the key in it\n\t\tis used - if it does not exist, a new key is generated and\n\t\tsaved to it\n"
echo "-c <file name of old certificate>\tThe file containing the old\n\t\tcertificate that should be renewed\n"
echo "-o <file name of resulting CSR>\tThe file the new certificate signing\n\t\trequest is to be saved in\n"
echo "-h\t\tPrint this help text\n"
}
while getopts ":k:c:o:h" opt; do
  case $opt in
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		key_file_location=$OPTARG
      ;;
    c)
#      echo "-c was triggered! ($OPTARG)" >&2
		cert_file_location=$OPTARG
     ;;
    o)
#      echo "-o was triggered! ($OPTARG)" >&2
		csr_file_location=$OPTARG
     ;;
    h)
	  printHelp
      exit 0
	  ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
	  printHelp
      optionerror=1
      ;;
	:)
      echo "Option -$OPTARG requires an argument." >&2
	  printHelp
      optionerror=1
      ;;
  esac
done
if [ "$optionerror" = "1" ] 
then
	exit 1
fi

if [ "$key_file_location" = "" ]; then
	echo "key_file_location must be given (specify via -k)" >&2
	exit 
fi
if [ "$cert_file_location" = "" ]; then
	echo "cert_file_location must be given (specify via -c)" >&2
	exit 
fi
if [ "$csr_file_location" = "" ]; then
	echo "csr_file_location must be given (specify via -o)" >&2
	exit 
fi

openssl x509 -in "${cert_file_location}" -signkey "${key_file_location}" -x509toreq -out "${csr_file_location}"
