#!/bin/sh
printHelp ()
{
echo "usage: $0 [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo "-d <directory name to copy CRL to>\tThe directory\n\t\twhere the resulting CRL should be placed\n"
echo "-h\t\tPrint this help text\n"
}
dialog_exe=dialog
. `dirname $0`/logging.sh
. `dirname $0`/configure_gui.sh
optionerror=0
_temp="/tmp/answer.$$"

destination_dir_for_crl=""
while getopts ":d:h" opt; do
  case $opt in
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
  esac
done
if [ "$optionerror" = "1" ]
then
	exit 1
fi

zip_file_location=""
script_dir=`dirname $0`
script=`basename $0`
ca_dir_name=""

ca_dir_name=`realpath .`
debug2Syslog "ca_dir_name $ca_dir_name"

layout_error=0
if [ ! -d "${ca_dir_name}/ca" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/certs" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then
  $dialog_exe --backtitle "Error" --msgbox "Script must be started from within a CA directory - containing three directories named ca, certs and crl!" 9 52
  exit 126;
fi

echo "weiter"

ca_name=`basename ${ca_dir_name}`

debug2Syslog "ca_name $ca_name"

db_name=`du -a .|grep "\.db$"|cut -f 2` #cut ohne -d meint tab

debug2Syslog "db_name $db_name"

n=0
menuitems=""
while read -r line
do
#    echo "line read from file - $line"
	state=`echo -n "$line"|cut -f 1`
	valid_end=`echo -n "$line"|cut -f 2`
	revoked_date=`echo -n "$line"|cut -f 3`
	serial=`echo -n "$line"|cut -f 4`
	unknown=`echo -n "$line"|cut -f 5`
	cn=`echo -n "$line"|cut -f 6| sed -n 's/.*CN=\(.*\)/\1/p'`
#	$dialog_exe --msgbox "_${dn}_\n$state $serial _${cn}_" 0 0
	if [ "$state" = "V" ]; then
		if [ "$menuitems" = "" ]; then
echo "empty"
			menuitems="$serial${cn}%" # subst. Blanks with "_"
			sel="$serial${cn}"
		else
			menuitems="$menuitems%$serial${cn}% " # subst. Blanks with "_"
		fi
	    n=`expr $n + 1`
	fi
#if  [ "$n" = 1 ]; then break; fi
done < "$db_name"
if [ ! $n -eq 1 ]; then
debug2Syslog "menuitems $menuitems"
#menuitems=`echo -n $menuitems | sed -e 's/.//'`
IFS=$'%'
    $dialog_exe --backtitle "Valid Certificates in data base" \
           --title "Select one" --menu \
           "Choose one of the valid certificates to revoke" 0 0 0 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
    else
      exit 12
    fi
		debug2Syslog "sel $sel"
n=0
fi
#           $dialog_exe --msgbox "$sel" 0 0

#das folgende, weil POSIX shell!!
IFS='
'
certs=`ls certs/*.crt`

for item in ${certs}
do
#$dialog_exe --msgbox "$item _${serial}${cn}_\n_${sel}_" 0 0
serial=-1
revoked_cert=""
#echo "${item}"
	serial=`openssl x509 -noout -serial -in "${item}" |cut -d "=" -f 2`
	cn=$(openssl x509 -noout -subject -in "${item}" | sed -n '/.*/s/^.*CN\s=\s//p'|sed  's/"//g')
#	$dialog_exe --msgbox "_${serial}${cn}_\n_${sel}_" 0 0
	if [ "$sel" = "$serial$cn" ]; then
		revoked_cert=${item}
		break
	fi
done

debug2Syslog "serial $serial"
if [ "$revoked_cert" != "" ]; then

options="superseded%unspecified%keyCompromise%CACompromise%affiliationChanged%cessationOfOperation%certificateHold%removeFromCRL"
menuitems="0%superseded%1%unspecified%2%keyCompromise%3%CACompromise%4%affiliationChanged%5%cessationOfOperation%6%certificateHold%7%removeFromCRL"
IFS=$'%'

#$dialog_exe --msgbox "$menuitems" 0 0
$dialog_exe --backtitle "Valid Certificates in data base" \
           --title "Select one" --menu \
           "Choose one of the certificates to show detailed information" 0 0 0 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
    else
      exit 13
    fi
		debug2Syslog "sel $sel"

n=0
    for item in ${options}
    do
		if [ "$sel" = "$n" ]
		then
        selection=${item}
		fi
        n=`expr $n + 1`
    done
        debug2Syslog "You choose: $sel --> $selection"
revocationReason=$selection
#das folgende, weil POSIX shell!!
IFS='
'

openssl x509 -text -in ${revoked_cert} > /tmp/cert.pem

$dialog_exe --backtitle "Certificate about to be revoked" --textbox /tmp/cert.pem 0 0

$dialog_exe --backtitle "Decision" --yesno "Do You want to revoke this certificate\nand update the crl?" 0 0
if [ $? -eq 0 ]; then
ca_name=`basename ${ca_dir_name}`

if [ ! -e "ca/${ca_name}-ca.crt" ]; then
	echo "could not find ca/"${ca_name}"-ca.crt" 
	ca_name=`du -a |grep "private$"|cut -f 2`
	ca_name=`realpath ${ca_name}`
	ca_name=`echo -n ${ca_name}|rev|cut -d "/" -f 2|rev|sed "s/-ca$//g"`
	echo $ca_name
fi
debug2Syslog "ca_name $ca_name"

cn=`openssl x509 -noout -subject -in ca/${ca_name}-ca.crt| sed -n '/^subject/s/^.*CN\s*=\s*//p'`

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Password" --clear --insecure --passwordbox "Please give private key password for\n${cn}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

#$dialog_exe --msgbox "_${revoked_cert}_etc/${ca_name}-ca.conf" 0 0

expect "${script_dir}/revoke_cert.xpct" "etc/${ca_name}-ca.conf" "${revoked_cert}" "${priv_key_pass}" "$revocationReason"

expect "${script_dir}/gen_crl.xpct" "etc/${ca_name}-ca.conf" "crl/${ca_name}-ca.crl" "${priv_key_pass}"
#openssl ca -gencrl -config etc/${ca_name}-ca.conf -out crl/${ca_name}-ca.crl

priv_key_pass=""

openssl crl -noout -text  -in crl/${ca_name}-ca.crl > /tmp/crl.pem

openssl crl -inform PEM -outform DER -in crl/${ca_name}-ca.crl -out crl/${ca_name}-ca.der

#infomsg
$dialog_exe --backtitle "CRL" --textbox /tmp/crl.pem 0 0

#ca=${new_ca_name}
#cpsresources=`grep -e "^CPS\s*=.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed s/\"//g`
#addresources=`grep \$base_url ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2|rev|cut -d "#" -f 2|rev|sed -E "s/^\s*//g"|sed -E "s/ca.(cer|crl)/${new_ca_name}.\1/g"`
base_url=`grep -e "^base_url\s*=\s*.*$" etc/${ca_name}"-ca.conf"|cut -d "=" -f 2| sed -E "s/^\s*//g"`
#$dialog_exe --title "resources" --cr-wrap --msgbox "$ca \n $base_url \n ${new_ca_name}\n ${addresources}" 12 52
resources="${base_url}/${ca_name}.crl"

if [ ! -z "$destination_dir_for_crl" ] ; then
  if [ -d "${destination_dir_for_crl}" ] ; then
    cp "crl/${ca_name}-ca.crl" "$destination_dir_for_crl"
  fi
fi
#infomsg
$dialog_exe --backtitle "Resources to provide" --msgbox "You must provide the updated CRL NOW\n
to make the changes visible:\n$resources" 14 64

mkdir -p "certs/revoked"
mv "${revoked_cert}" "certs/revoked/"
filename=$(basename -- "$revoked_cert")
extension="${revoked_cert##*.}"
filename="${revoked_cert%.*}"
#$dialog_exe --msgbox "$filename" 0 0
mv "${filename}.der" "certs/revoked/"
fi
fi


clear
