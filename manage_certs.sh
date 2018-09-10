#!/bin/sh
dialog_exe=dialog
. `dirname $0`/configure_gui.sh
optionerror=0
_temp="/tmp/answer.$$"
zip_file_location=""
script_dir=`dirname $0`
ca_dir_name=""

ca_dir_name=`realpath .`

layout_error=0
if [ ! -d "${ca_dir_name}/ca" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/certs" ]; then layout_error=1; fi
if [ ! -d "${ca_dir_name}/crl" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then exit 126; fi

echo "weiter"

ca_name=`basename ${ca_dir_name}`

echo $ca_name

db_name=`du -a .|grep "\.db$"|cut -f 2` #cut ohne -d meint tab

echo $db_name

continue=1
while [ $continue -ne 0 ]
do
ca_expiration=`LC_ALL=en_US.utf8 dialog --stdout --date-format "%B %d %H:%M:%S %Y" --calendar "Date the displayed certificates must be expired before" 0 0`
#$dialog_exe --backtitle "date" --msgbox "#${ca_expiration}#" 9 52
if [ "$ca_expiration" = "" ]; then
ca_expiration_seconds=""
ca_expiration_ts=""
else
ca_expiration_ts=$(date -d "${ca_expiration}" +%Y%m%d%H%M%S)
ca_expiration_seconds=$(date -d "${ca_expiration}" +%s)
fi
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
	dn=`echo -n "$line"|cut -f 6`
	cn=`echo -n $dn| sed -n '/.*/s/^.*CN\s=\s//p'`
n=0
#das folgende, weil POSIX shell!!
IFS='
'
certs=`ls ca/*.crt`

for item in ${certs}
do
ser=-1
lookedat_cert=""
#echo "${item}"
	ser=`openssl x509 -noout -serial -in "${item}" |cut -d "=" -f 2`
	if [ "$ser" = "$serial" ]; then 
		lookedat_cert=${item}
cert_expiration=`openssl x509 -noout -dates -in ${lookedat_cert}|grep notAfter|cut -d "=" -f 2`
	cert_expiration_ts=$(date -d "${cert_expiration}" +%Y%m%d%H%M%S)
	cert_expiration_seconds=$(date -d "${cert_expiration}" +%s)
		break
	fi
done

#$dialog_exe --backtitle "date" --msgbox "#${valid_end}#${ca_expiration_seconds}#${cert_expiration_seconds}#" 9 52

	echo $state $serial $cn
	if [ "$ca_expiration_seconds" = "" ] || [ "$state" = "V" ]; then
#$dialog_exe --backtitle "date" --msgbox "#${ca_expiration_seconds}#${cert_expiration_seconds}#" 9 52
		if [ "$ca_expiration_seconds" = "" ] || [ "$ca_expiration_seconds" -gt "$cert_expiration_seconds" ]; then
			if [ "$menuitems" = "" ]; then
				echo "empty"
				menuitems="$serial%"
				if [  "$ca_expiration_seconds" = "" ];then 
				menuitems="$menuitems${state} "
				fi
				menuitems="$menuitems${cn} (${dn})" # subst. Blanks with "_"  
			else
				menuitems="$menuitems%$serial%"
				if [  "$ca_expiration_seconds" = "" ];then 
				menuitems="$menuitems${state} "
				fi
				menuitems="$menuitems${cn} (${dn})" # subst. Blanks with "_"  
			fi
			n=`expr $n + 1`
		fi
	fi
#if  [ "$n" = 1 ]; then break; fi
done < "$db_name"
#echo $menuitems
#menuitems=`echo -n $menuitems | sed -e 's/.//'`
#echo $menuitems
IFS=$'%'
    $dialog_exe --backtitle "Valid Certificates in data base" \
           --title "Select one" --menu \
           "Choose one of the certificates to show detailed information" 0 0 0 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		echo $sel
n=0
#das folgende, weil POSIX shell!!
IFS='
'
certs=`ls ca/*.crt`

for item in ${certs}
do
serial=-1
revoked_cert=""
#echo "${item}"
	serial=`openssl x509 -noout -serial -in "${item}" |cut -d "=" -f 2`
	if [ "$sel" = "$serial" ]; then 
		revoked_cert=${item}
		break
	fi
done

echo $serial
if [ "$revoked_cert" != "" ]; then
openssl x509 -text -in ${revoked_cert} > /tmp/cert.pem

$dialog_exe --backtitle "Certificate details" --textbox /tmp/cert.pem 0 0

fi
else
continue=0
fi
done
