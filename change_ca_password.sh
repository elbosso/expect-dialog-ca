#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <file name for private key file of the CA>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-k <file name for private key file of the CA>\t\n\tThe file containing the private key of the CA\n"
echo -e "-l \trefresh CRL\n"
echo -e "-d <directory name to copy CRL to>\tThe directory\n\t\twhere the resulting CRL should be placed\n\t\t(only used if -l is set)\n"
echo -e "-h\t\tPrint this help text"
}
dialog_exe=dialog
. `dirname $0`/logging.sh
. `dirname $0`/configure_gui.sh
. `dirname $0`/get_private_key_file.sh
layout_error=0
if [ ! -d "./ca" ]; then layout_error=1; fi
if [ ! -d "./certs" ]; then layout_error=1; fi
if [ ! -d "./crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then
  $dialog_exe --backtitle "Error" --msgbox "Script must be started from within a CA directory - containing three directories named ca, certs and crl!" 9 52
  exit 126;
fi

script_dir=`dirname $0`
script=`basename $0`
ca_dir_name=""
privkey_file_name=""
_temp="/tmp/answer.$$"
destination_dir_for_crl=""
should_also_refresh_crl=""

while getopts ":k:d:hl" opt; do
  case $opt in
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		privkey_file_name=$OPTARG
      ;;
    l)
#      echo "-l was triggered!" >&2
		should_also_refresh_crl="should_also_refresh_crl"
      ;;
    d)
#      echo "-d was triggered! ($OPTARG)" >&2
		destination_dir_for_crl=$OPTARG
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
debug2Syslog "ca_dir_name $ca_dir_name"
#der private Schlüssel wird ausgewählt

get_private_key_file "$ca_dir_name" "$privkey_file_name" "$dialog_exe"

ca=`basename ${privkey_file_name}|cut -d "." -f 1 |rev| cut -d "-" -f 2-|rev`
if [ ! -d "./ca/db" ]; then layout_error=1; fi
if [ ! -d "./ca/private" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then
  $dialog_exe --backtitle "Error" --msgbox "Script must be started from within a CA directory - containing two directories named ca/db and ca/private!" 9 52
  exit 128;
fi

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

#echo "expect ${script_dir}/change_ca_password.xpct ${privkey_file_name}.bck ${privkey_file_name} ${priv_key_pass} ${Password}" >/tmp/te

expect "${script_dir}/change_ca_password.xpct" "${privkey_file_name}.bck" "${privkey_file_name}" "${priv_key_pass}" "${Password}"

if [ -s "${privkey_file_name}" ]; then
  $dialog_exe --backtitle "Success!" --msgbox "Password for ${privkey_file_name} changed to ${Password}" 0 0
  rm "${privkey_file_name}.bck"
  if [ ! -z "$should_also_refresh_crl" ] ; then
    ca_name=`basename ${ca_dir_name}`
    expect "${script_dir}/gen_crl.xpct" "etc/${ca_name}-ca.conf" "crl/${ca_name}-ca.crl" "${priv_key_pass}"
    if [ ! -z "$destination_dir_for_crl" ] ; then
      if [ -d "${destination_dir_for_crl}" ] ; then
        cp "crl/${ca_name}-ca.crl" "$destination_dir_for_crl"
      fi
    fi
  fi
else
  $dialog_exe --backtitle "Error!" --msgbox "Password for ${privkey_file_name} not changed - maybe you did not give the correct old password?" 0 0
  mv "${privkey_file_name}.bck" "${privkey_file_name}"
fi

Password=""
priv_key_pass=""


clear
