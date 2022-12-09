#!/bin/sh
printHelp ()
{
echo "usage: $0 [-z <location of zip file holding the certificate (and other stuff)>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo "-z <location of zip file holding the certificate>\tThe file with\n\t\tthe deliverables in it that the CA sent back\n"
echo "-h\t\tPrint this help text\n"
}
dialog_exe=dialog
. `dirname $0`/logging.sh
. `dirname $0`/configure_gui.sh
optionerror=0
_temp="/tmp/answer.$$"
zip_file_location=""
script_dir=`dirname $0`
script=`basename $0`
ca_dir_name=""
while getopts ":z:h" opt; do
  case $opt in
    z)
#      echo "-z was triggered! ($OPTARG)" >&2
		zip_file_location=$OPTARG
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

condition=1;
while [ $condition -eq 1 ]
do
condition=0
if [ "$zip_file_location" = "" ]; then
	zip_file_location=$($dialog_exe --stdout --backtitle "Certificate deliverables zip file location" --fselect "" $(expr $(tput lines) - 12 ) 90)
	if [ ${?} -ne 0 ]; then exit 127; fi
fi
	if [ "$zip_file_location" = "" ]; then
	echo "A zip file must be given!"
	$dialog_exe --backtitle "Error" --msgbox "A zip file must be given!" 0 0 
	condition=1;
	zip_file_location=""
	elif [ ! -f "$zip_file_location" ]; then
	echo "A zip file must be a file!"
	$dialog_exe --backtitle "Error" --msgbox "A zip file must be a file!" 0 0
	condition=1;
	zip_file_location=""
	fi
done
ca_dir_name=`realpath .`
debug2Syslog "ca_dir_name $ca_dir_name"

layout_error=0
if [ ! -d "${ca_dir_name}/ca" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/certs" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then exit 126; fi

echo "weiter"

if [ -d /tmp/ca_rollout ]; then
	rm -rf /tmp/ca_rollout
fi
mkdir -p /tmp/ca-rollout
unzip -o "${zip_file_location}" -d /tmp/ca-rollout 
subject=`basename "${zip_file_location}"|rev|cut -d "." -f 2|rev`

debug2Syslog "subject $subject"
. /tmp/ca-rollout/index.txt
debug2Syslog "issuer $issuer"
debug2Syslog "zert $zert"

ca_name=`basename ${ca_dir_name}`

debug2Syslog "ca_name $ca_name"

timestamp=$(date +%Y-%m-%d_%H-%M-%S)
if [ -e "ca/${ca_name}-ca.crt" ]; then
  cp "ca/${ca_name}-ca.crt" "ca/${ca_name}_${timestamp}-ca.crt"
fi
cp "/tmp/ca-rollout/${zert}" "ca/${ca_name}-ca.crt"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
if [ -e "ca/${ca_name}-ca.der" ]; then
  cp "ca/${ca_name}-ca.der" "ca/${ca_name}_${timestamp}-ca.der"
fi
cp "/tmp/ca-rollout/${zertDER}" "ca/${ca_name}-ca.der"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
if [ -e "ca/${ca_name}-ca.cer" ]; then
  cp "ca/${ca_name}-ca.cer" "ca/${ca_name}_${timestamp}-ca.cer"
fi
cp "/tmp/ca-rollout/${zertDER}" "ca/${ca_name}-ca.cer"

cn=`openssl x509 -noout -subject -in ca/${ca_name}-ca.crt| sed -n '/^subject/s/^.*CN\s=\s//p'`

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Password" --clear --insecure --passwordbox "Please give private key password for\n${cn}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

expect "${script_dir}/gen_crl.xpct" "etc/${ca_name}-ca.conf" "crl/${ca_name}-ca.crl" "${priv_key_pass}"
#openssl ca -gencrl -config etc/${ca_name}-ca.conf -out crl/${ca_name}-ca.crl

priv_key_pass=""

openssl crl -noout -text  -in crl/${ca_name}-ca.crl > /tmp/crl.pem

openssl crl -inform PEM -outform DER -in crl/${ca_name}-ca.crl -out crl/${ca_name}-ca.der

#infomsg
$dialog_exe --backtitle "CRL" --textbox /tmp/crl.pem 0 0

cat "ca/${ca_name}-ca.crt" "/tmp/ca-rollout/${issuer}" > ca/${ca_name}-ca-chain.pem

openssl x509 -noout  -text  -in ca/${ca_name}-ca-chain.pem > /tmp/chain.pem

#infomsg
$dialog_exe --backtitle "Chain" --textbox /tmp/chain.pem 0 0

#ca=${new_ca_name}
cpsresources=`grep -e "^CPS\s*=.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed s/\"//g`
#addresources=`grep \$base_url ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2|rev|cut -d "#" -f 2|rev|sed -E "s/^\s*//g"|sed -E "s/ca.(cer|crl)/${new_ca_name}.\1/g"`
base_url=`grep -e "^base_url\s*=\s*.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed -E "s/^\s*//g"`
#$dialog_exe --title "resources" --cr-wrap --msgbox "$ca \n $base_url \n ${new_ca_name}\n ${addresources}" 12 52
resources="${base_url}/${ca_name}.crt\n${base_url}/${ca_name}.crl\n${cpsresources}"

#infomsg
$dialog_exe --backtitle "Resources to provide" --msgbox "You must provide the following resources NOW\n
to make your shiny new CA fully functional:\n$resources" 0 0


clear
