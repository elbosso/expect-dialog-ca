#!/bin/bash

printHelp ()
{
echo "usage: $0 [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-d <target directory to copy the CRLs to>\tAll CRLs found inside\n\t\tany of the subdirectories of the current directory \n\t\tare copied to this directory\n"
echo -e "-h\t\tPrint this help text\n"
}

dialog_exe=dialog
. `dirname $0`/logging.sh
. `dirname $0`/configure_gui.sh
optionerror=0

while getopts ":d:h" opt; do
  case $opt in
    d)
#      echo "-s was triggered! ($OPTARG)" >&2
		targetdirectory=$OPTARG
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

script_dir=`dirname $0`
script=`basename $0`

crls=$(find . -type f -path '*crl*/*' -name '*.crl' ! -path '*trash*/*' ! -path '*revoked*/*')

#Set the field separator to new line
IFS=$'\n'

if [ -z ${targetdirectory+x} ]; then
  targetdirectory=$($dialog_exe --stdout --backtitle "Target Directory" --fselect "./" $(expr $(tput lines) - 12 ) $(expr $(tput cols) - 10 ))
  if [ ${?} -ne 0 ]; then exit 127; fi
fi
debug2Syslog "targetdirectory $targetdirectory"

mkdir -p "$targetdirectory"

for crl in ${crls}
do
  debug2Syslog "copying $crl to $targetdirectory"
  cp "$crl" "$targetdirectory"
done
