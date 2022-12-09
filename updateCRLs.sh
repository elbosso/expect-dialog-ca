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

for ca in ${cas}
do
  cap=$(realpath -s "$ca")
  rp=$(dirname "$cap")
  rp="$rp/../../"
  cd "$rp"
  "$rootOfAllEvil/refresh_crl.sh" -k "$cap"
  cd "$rootOfAllEvil"
done
