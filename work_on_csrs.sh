#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <file name for private key file of the CA>] [-d <directory containing the CSRs to work on>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo "-k <file name for private key file of the CA>\tThe file containing the private key of the CA"
echo "-d <directory containing the CSRs to work on>\tAll files found inside this directory with suffix \".csr\" are processed as certificate signing request"
echo "-h\t\tPrint this help text"
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
sign_req_name=""
privkey_file_name=""
. ${script_dir}/preset_${script}
_temp="/tmp/answer.$$"

while getopts ":d:k:h" opt; do
  case $opt in
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		privkey_file_name=$OPTARG
      ;;
    d)
#      echo "-s was triggered! ($OPTARG)" >&2
		sign_req_directory=$OPTARG
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

if [ -z ${sign_req_directory+x} ]; then
  sign_req_directory=$($dialog_exe --title "Choose a directory containing certificate signing requests" --stdout --title "CSR directory" --dselect /tmp/ 0 0)
fi

if [ -d "$sign_req_directory" ]; then
  mkdir -p "$sign_req_directory/done"
  cd "$sign_req_directory" || exit
  csrs=$(ls *.csr)
  cd - || exit
  echo "$csrs"

  for current_csr in ${csrs}
  do
    $dialog_exe --backtitle "Decision" --yesno "Do You want to continue working on\n${current_csr}?" 0 0
    if [ ! $? -eq 0 ]; then
      exit 0
    fi
    "$script_dir/sign_request.sh" -k "$privkey_file_name" -s "$sign_req_directory/$current_csr"
    mv "$sign_req_directory/$current_csr" "$sign_req_directory/done"
  done
fi
