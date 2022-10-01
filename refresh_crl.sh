#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <file name for private key file of the CA>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-k <file name for private key file of the CA>\tThe file\n\t\tcontaining the private key of the CA\n"
echo -e "-h\t\tPrint this help text\n"
}
dialog_exe=dialog
. `dirname $0`/configure_gui.sh
layout_error=0
if [ ! -d "./ca" ]; then layout_error=1; fi
if [ ! -d "./certs" ]; then layout_error=1; fi
if [ ! -d "./crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then exit 126; fi

script_dir=`dirname $0`
script=`basename $0`
ca_dir_name=""
privkey_file_name=""
. ${script_dir}/preset_${script}
_temp="/tmp/answer.$$"

while getopts ":s:k:h" opt; do
  case $opt in
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		privkey_file_name=$OPTARG
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

ca_dir_name=`realpath .`
#der private Schlüssel wird ausgewählt

get_private_key_file "$ca_dir_name" "$privkey_file_name" "$dialog_exe"

ca=`basename ${privkey_file_name}|cut -d "." -f 1 |rev| cut -d "-" -f 2-|rev`
if [ ! -d "./ca/db" ]; then layout_error=1; fi
if [ ! -d "./ca/private" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then exit 128; fi

# Das Konfigurationsverzeichnis der CA wird gesucht

hyp=`dirname ${privkey_file_name}`/../etc
if [ ! -d "$hyp" ]; then
	hyp=`dirname ${privkey_file_name}`/../../etc
	hyp=`realpath ${hyp}`
fi

if [ ! -d "$hyp" ]; then
	ca_confdir_name=$($dialog_exe --stdout --backtitle "CA config directory" --dselect "$ca_dir_name" 0 90)
	if [ ${?} -ne 0 ]; then exit 127; fi   
	if [ "$ca_dir_name" = "" ]; then
	echo "A CA config directory must be given!"
	$dialog_exe --backtitle "Error" --msgbox "A CA config directory must be given!" 9 52
	exit 4
	fi
else
	ca_confdir_name=$hyp
fi

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Password" --clear --insecure --passwordbox "Please give private key password for\n${ca}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

ca_name=`basename ${ca_dir_name}`

expect "${script_dir}/gen_crl.xpct" "etc/${ca_name}-ca.conf" "crl/${ca_name}-ca.crl" "${priv_key_pass}"
#$dialog_exe --backtitle "Outcome:!" --msgbox "$?" 0 0
if [ $? -eq 0 ]; then
#openssl ca -gencrl -config etc/${ca_name}-ca.conf -out crl/${ca_name}-ca.crl

priv_key_pass=""

openssl crl -noout -text  -in crl/${ca_name}-ca.crl > /tmp/crl.pem

#infomsg
$dialog_exe --backtitle "CRL" --textbox /tmp/crl.pem 0 0

openssl crl -inform PEM -outform DER -in crl/${ca_name}-ca.crl -out crl/${ca_name}-ca.der

#ca=${new_ca_name}
#cpsresources=`grep -e "^CPS\s*=.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed s/\"//g`
#addresources=`grep \$base_url ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2|rev|cut -d "#" -f 2|rev|sed -E "s/^\s*//g"|sed -E "s/ca.(cer|crl)/${new_ca_name}.\1/g"`
base_url=`grep -e "^base_url\s*=\s*.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed -E "s/^\s*//g"`
#$dialog_exe --title "resources" --cr-wrap --msgbox "$ca \n $base_url \n ${new_ca_name}\n ${addresources}" 12 52
resources="${base_url}/${ca_name}.crl"

#infomsg
$dialog_exe --backtitle "Resources to provide" --msgbox "You must provide the updated CRL NOW\n
to make the changes visible:\n$resources" 14 64
else
    $dialog_exe --backtitle "Error!" --msgbox "CRL not updated - maybe you did not give the correct password?" 0 0
fi
clear
