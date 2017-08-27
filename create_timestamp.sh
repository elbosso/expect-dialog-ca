#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-t <filename for timestamp request>] [-h]"
}
dialog_exe=dialog
. `dirname $0`/configure_gui.sh
layout_error=0
if [ ! -d "./ca" ]; then layout_error=1; fi
if [ ! -d "./certs" ]; then layout_error=1; fi
if [ ! -d "./crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then exit 126; fi
if [ ! -e "./etc/timestamp.conf" ]; then
    $dialog_exe --backtitle "Error" --msgbox "This is not a component CA!" 9 52
    clear
    exit 125
fi

script_dir=`dirname $0`
script=`basename $0`
ca_dir_name=""
privkey_file_name=""
_temp="/tmp/answer.$$"

while getopts ":s:t:" opt; do
  case $opt in
    t)
#      echo "-k was triggered! ($OPTARG)" >&2
		request_file_name=$OPTARG
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

#das Verzeichnis der CA wird ausgewählt
#if [ "$ca_dir_name" == "" ]; then
#	ca_dir_name=$($dialog_exe --stdout --backtitle "CA directory" --dselect ./ 0 90)
#	if [ ${?} -ne 0 ]; then exit 127; fi
#	if [ "$ca_dir_name" = "" ]; then
#	echo "A CA directory must be given!"
#	$dialog_exe --backtitle "Error" --msgbox "A CA directory must be given!" 9 52
#	exit 4
#	fi
#fi
ca_dir_name=`realpath .`
# Noch keine DI für TSA existiert
if [ ! -e "./ca/private/tsa.key" ]; then
purpose=" of timestamp authority"
. ../ask_for_passwd.sh
purpose=""

condition=1
while [ $condition -eq 1 ]
do
condition=0
countryName=$(grep countryName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
stateOrProvinceName=$(grep stateOrProvinceName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
localityName=$(grep localityName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
organizationName=$(grep organizationName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
organizationalUnitName=$(grep organizationalUnitName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
commonName=$(grep commonName_default "./etc/timestamp.conf"|cut -d " " -f 3|cut -d "\"" -f 2)
$dialog_exe --backtitle "CSR defaults for $item" \
	    --form " Specify defaults for $item - use [up] [down] to select input field " 0 0 0 \
	    "countryName" 2 4 "$countryName" 2 25 40 0\
	    "stateOrProvinceName" 4 4 "$stateOrProvinceName" 4 25 40 0\
	    "localityName" 6 4 "$localityName" 6 25 40 0\
	    "organizationName" 8 4 "$organizationName" 8 25 40 0\
	    "organizationalUnitName" 10 4 "$organizationalUnitName" 10 25 40 0\
	    "commonName" 12 4 "$commonName" 12 25 64 0\
	    2>$_temp

	if [ ${?} -ne 0 ]; then exit 127; fi
    result=`cat $_temp`
    echo "Result=$result"
countryName=`cat $_temp |cut -d"
" -f 1`
stateOrProvinceName=`cat $_temp |cut -d"
" -f 2`
localityName=`cat $_temp |cut -d"
" -f 3`
organizationName=`cat $_temp |cut -d"
" -f 4`
organizationalUnitName=`cat $_temp |cut -d"
" -f 5`
commonName=`cat $_temp |cut -d"
" -f 6`
if [ "$countryName" = "" ] || [ "$stateOrProvinceName" = "" ] || [ "$localityName" = "" ] || [ "$organizationName" = "" ] || [ "$organizationalUnitName" = "" ] || [ "$commonName" = "" ] ; then
echo "You must fill out all the fields!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
done





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

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Current Password" --clear --insecure --passwordbox "Please give private key password for\n${ca}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

. ./ask_for_passwd.sh

mv ${privkey_file_name} ${privkey_file_name}.bck

echo "expect "${script_dir}/change_ca_password.xpct" ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}" >/tmp/te

expect "${script_dir}/change_ca_password.xpct" ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}

Password=""
priv_key_pass=""
fi
#<<noch keine DI für TSA existiert

clear
