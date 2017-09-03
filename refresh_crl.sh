#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <filename for private key file of the CA>] [-h]"
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

while getopts ":s:k:" opt; do
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
if [ "$privkey_file_name" == "" ]; then
	privkey_file_name=$($dialog_exe --stdout --backtitle "CAs Private Key" --fselect "$ca_dir_name/ca/private/" 0 90)
	if [ ${?} -ne 0 ]; then exit 127; fi   
	if [ "$privkey_file_name" = "" ]; then
	echo "A private key must be given!"
	$dialog_exe --backtitle "Error" --msgbox "A private key must be given!" 9 52
	exit 4
	fi
fi
ca=`basename ${privkey_file_name}|cut -d "." -f 1 |cut -d "-" -f 1`
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
#openssl ca -gencrl -config etc/${ca_name}-ca.conf -out crl/${ca_name}-ca.crl

priv_key_pass=""

openssl crl -noout -text  -in crl/${ca_name}-ca.crl > /tmp/crl.pem

$dialog_exe --backtitle "CRL" --textbox /tmp/crl.pem 0 0

openssl crl -inform PEM -outform DER -in crl/${ca_name}-ca.crl -out crl/${ca_name}-ca.der

clear
