#!/bin/bash

printHelp ()
{
echo "usage: $0 [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-h\t\tPrint this help text\n"
}

dialog_exe=dialog
. `dirname $0`/logging.sh
. `dirname $0`/configure_gui.sh
optionerror=0

while getopts ":h" opt; do
  case $opt in
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

script_dir=`dirname $0`
script=`basename $0`

cas=$(find . -type f -path '*ca/private/*' -name '*.key' ! -path '*trash*/*' ! -path '*revoked*/*')

#Set the field separator to new line
IFS=$'\n'

rootOfAllEvil=$(realpath "$script_dir")

calpresetd=$(date --date "+2 weeks" +"%d")
calpresetm=$(date --date "+2 weeks" +"%m")
calpresety=$(date --date "+2 weeks" +"%Y")
stichtag=$($dialog_exe --calendar --stdout "Planned expiration" 0 0 ${calpresetd} ${calpresetm} ${calpresety})
if [ $? -ne 0 ]; then exit 127; fi

#$dialog_exe --backtitle "CRLENDOFLIFE" --msgbox "$stichtag" 9 52


y=`echo -n "${stichtag}"|cut -d "/" -f 3`
m=`echo -n "${stichtag}"|cut -d "/" -f 2`
d=`echo -n "${stichtag}"|cut -d "/" -f 1`

#$dialog_exe --backtitle "yms" --msgbox "$y $m $d" 9 52

#st=$(date --date "${y}-${m}-${d}")

#$dialog_exe --backtitle "st" --msgbox "$st" 9 52


for ca in ${cas}
do
  cap=$(realpath -s "$ca")
  rp=$(dirname "$cap")
  rp="$rp/../../"
  cd "$rp"
#  ca_=`readlink -f ${rp}`
#  ca_=`basename ${ca_}`
  ca_=`basename ${cap}|cut -d "." -f 1 |rev| cut -d "-" -f 2-|rev`
  #$dialog_exe --backtitle "cap" --msgbox "$cap" 9 52  
#  $dialog_exe --backtitle "ca_" --msgbox "$ca_" 9 52  
  crl="${rp}/crl/${ca_}-ca.crl"
  #$dialog_exe --backtitle "crl" --msgbox "$crl" 9 52 
  CRLENDOFLIFE=$(openssl crl -in "${crl}" -nextupdate -noout|cut -d '=' -f 2)
#  $dialog_exe --backtitle "CRLENDOFLIFE" --msgbox "$CRLENDOFLIFE" 9 52
  DATEFUTURE=$(date --date="$CRLENDOFLIFE" "+%s")
  DATENOW=$(date --date "${y}${m}${d}" "+%s")
  SECONDSDIFF=$(($DATEFUTURE - $DATENOW))
  
  if [ $SECONDSDIFF -le 0 ]; then
    "$rootOfAllEvil/refresh_crl.sh" -k "$cap"
#    $dialog_exe --backtitle "tobedone" --msgbox "$ca_" 9 52
  fi
  cd "$rootOfAllEvil"
done
