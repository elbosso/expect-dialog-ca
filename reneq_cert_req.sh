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

chain_name=`du -a .|grep "chain.pem$"|cut -f 2` #cut ohne -d meint tab

echo $chain_name

ca_name=`basename ${ca_dir_name}`

echo "$ca_name"
if [ ! -e "ca/${ca_name}-ca.crt" ]; then
	echo "could not find ca/"${ca_name}"-ca.crt" 
	ca_name=`du -a |grep "private$"|cut -f 2`
	ca_name=`realpath ${ca_name}`
	ca_name=`echo -n ${ca_name}|rev|cut -d "/" -f 2|rev|sed "s/-ca$//g"`
	echo $ca_name
fi

stem=`dirname ${chain_name}`

csr_name=${stem}"/"${ca_name}"-ca.csr"
crt_name=${stem}"/"${ca_name}"-ca.crt"
key_name=${stem}"/private/"${ca_name}"-ca.key"
ts=`date +%F_%T`

mkdir -p ${ts}
cp -a ${csr_name} ${ts}
cp -a ${crt_name} ${ts}
 
echo $ts

echo $csr_name $crt_name $key_name

log_file_name=$($dialog_exe --stdout --backtitle "Log" --fselect ./${ca_name}_log.tsv 0 0)
if [ ${?} -ne 0 ]; then exit 127; fi   

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Password" --clear --insecure --passwordbox "Please give private key password for\n${ca_name}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

expect "${script_dir}/req_from_cert.xpct" "${crt_name}" "${key_name}" "${csr_name}" "${priv_key_pass}"
#openssl x509 -in "${crt_name}" -signkey "${key_name}" -x509toreq -out "${csr_name}"

openssl req -text -in "${csr_name}" -out /tmp/csr.pem

$dialog_exe --backtitle "Certificate Request" --textbox /tmp/csr.pem 0 0

$dialog_exe --backtitle "Info" --msgbox "The key is in ${key_name}\nThe Cert Req is in ${csr_name}\n\nYou can now ask your CA to sign the request!" 9 52

#log schreiben

cn=`openssl req -noout -subject -in ${csr_name}| sed -n '/^subject/s/^.*CN=//p'`
if [ "$log_file_name" != "" ]; then
echo "name\tCN\tprivate key pass" > ${log_file_name}
echo "${ca_name}\t${cn}\t${priv_key_pass}" >> ${log_file_name}
chmod 600 ${log_file_name}
$dialog_exe --backtitle "Info" --msgbox "log file written to ${log_file_name}" 0 0
fi

