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

proposed_pass=`makepasswd -count 1 -minchars 8`
condition=1
while [ $condition -eq 1 ]
do
condition=0
result=$($dialog_exe --stdout --backtitle "Password for private key" \
	    --form " Please specify - use [up] [down] to select input field " 0 0 0 \
	    "Password" 2 4 "$proposed_pass" 2 25 40 0\
	    "Verification" 4 4 "" 4 25 40 0)

	if [ ${?} -ne 0 ]; then exit 127; fi
#    result=`cat $_temp`
    echo "Result=$result"

Password=`echo "$result"|cut -d"
" -f 1`
Verification=`echo "$result" |cut -d"
" -f 2`
#$dialog_exe --backtitle "Info" --msgbox "$result\n--\n$Password\n$Verification" 9 52
if [ "$Password" = "" ] || [ "$Verification" = "" ]; then
echo "You must fill out all the fields!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
if [ "$Verification" != "$Password" ] && [ $condition -eq 0 ]; then
echo "Password and verification differ!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields identically!" 9 52
condition=1
fi
if [ ${#Password} -lt 4 ] && [ $condition -eq 0 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done
proposed_pass=""

mv ${privkey_file_name} ${privkey_file_name}.bck

echo "expect "${script_dir}/change_ca_password.xpct" ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}" >/tmp/te

expect "${script_dir}/change_ca_password.xpct" ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}

Password=""
priv_key_pass=""


clear
