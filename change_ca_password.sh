#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <file name for private key file of the CA>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-k <file name for private key file of the CA>\t\n\tThe file containing the private key of the CA\n"
echo -e "-h\t\tPrint this help text"
}
dialog_exe=dialog
. `dirname $0`/configure_gui.sh
. `dirname $0`/get_private_key_file.sh
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

while getopts ":k:h" opt; do
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

get_private_key_file "$ca_dir_name" "$privkey_file_name" "$dialog_exe"

ca=`basename ${privkey_file_name}|cut -d "." -f 1 |rev| cut -d "-" -f 2-|rev`
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

. "$script_dir"/ask_for_passwd.sh

mv ${privkey_file_name} ${privkey_file_name}.bck

echo "expect ${script_dir}/change_ca_password.xpct ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}" >/tmp/te

expect "${script_dir}/change_ca_password.xpct" "${privkey_file_name}.bck" "${privkey_file_name}" "${priv_key_pass}" "${Password}"

if [ -s "${privkey_file_name}" ]; then
  $dialog_exe --backtitle "Success!" --msgbox "Password for ${privkey_file_name} changed to ${Password}" 0 0
  rm "${privkey_file_name}.bck"
else
  $dialog_exe --backtitle "Error!" --msgbox "Password for ${privkey_file_name} not changed - maybe you did not give the correct old password?" 0 0
  mv "${privkey_file_name}.bck" "${privkey_file_name}"
fi

Password=""
priv_key_pass=""


clear
