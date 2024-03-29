#!/bin/bash
#Dieses Skript signiert Zertifikatsrequests
printHelp ()
{
echo "usage: $0 [-k <file name for private key file of the CA>] [-s <file name of the CSR to work on>] [-d <end day of validity>] [-m <end month of validity>] [-y <validity in years>] [-y <validity in months>] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo -e "-k <file name for private key file of the CA>\tThe file containing the\n\t\tprivate key of the CA\n"
echo -e "-s <file name of the CSR to work on>\tA file containing the certificate\n\t\tsigning request to be processed\n"
echo -e "-d the calendar dialog for choosing the validity end of the certificate\n\t\tis preset to this date\n"
echo -e "-m the calendar dialog for choosing the validity end of the certificate\n\t\tis preset to this date (only if -M ist *NOT* specified!)\n"
echo -e "-y the calendar dialog shows a date the given amount of years in the\n\t\tfuture - taking into account the values for -m and -d if given\n"
echo -e "-M the calendar dialog shows a date the given amount of months in the\n\t\tfuture - taking into account the value for -d if given\n"
echo -e "-h\t\tPrint this help text\n"
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
sign_req_name=""
privkey_file_name=""
validityEndDay="%d"
validityEndMonth="%m"
if [ -e "${script_dir}/preset_${script}" ]; then
  . ${script_dir}/preset_${script}
fi
_temp="/tmp/answer.$$"

while getopts ":s:k:d:m:y:M:h" opt; do
  case $opt in
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		privkey_file_name=$OPTARG
      ;;
    s)
#      echo "-s was triggered! ($OPTARG)" >&2
		sign_req_name=$OPTARG
      ;;
    d)
  	  validityEndDay=$OPTARG
	    ;;
    m)
  	  validityEndMonth=$OPTARG
	    ;;
    y)
  	  validityInYears=$OPTARG
	    ;;
    M)
  	  validityInMonths=$OPTARG
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

get_private_key_file "$ca_dir_name" "$privkey_file_name" "$dialog_exe"

ca=`basename ${privkey_file_name}|cut -d "." -f 1 |rev| cut -d "-" -f 2-|rev`
if [ ! -d "./ca/db" ]; then layout_error=1; fi
if [ ! -d "./ca/private" ]; then layout_error=1; fi
if [ "$layout_error" = 1 ]; then
  $dialog_exe --backtitle "Error" --msgbox "Script must be started from within a CA directory - containing two directories named ca/db and ca/private!" 9 52
  exit 128;
fi

#der Signing Request wird ausgewählt
condition=1;
while [ $condition -eq 1 ]
do
condition=0
if [ "$sign_req_name" == "" ]; then
	sign_req_name=$($dialog_exe --stdout --backtitle "Signing Request" --fselect "" $(expr $(tput lines) - 12 ) 90)
	if [ ${?} -ne 0 ]; then exit 127; fi
fi
	if [ "$sign_req_name" = "" ]; then
	echo "A signing request must be given!"
	$dialog_exe --backtitle "Error" --msgbox "A signing request must be given!" 9 52
	condition=1;
	sign_req_name=""
	elif [ ! -f "$sign_req_name" ]; then
	echo "A signing request must be a file!"
	$dialog_exe --backtitle "Error" --msgbox "A signing request must be a file!" 9 52
	condition=1;
	sign_req_name=""
	fi
done

debug2Syslog "sign_req_name $sign_req_name"
# Das Konfigurationsverzeichnis der CA wird gesucht

hyp=`dirname ${privkey_file_name}`/../etc
if [ ! -d "$hyp" ]; then
	hyp=`dirname ${privkey_file_name}`/../../etc
	hyp=`realpath ${hyp}`
fi

if [ ! -d "$hyp" ]; then
	ca_confdir_name=$($dialog_exe --stdout --backtitle "CA config directory" --dselect "$ca_dir_name" 0 90)
	if [ ${?} -ne 0 ]; then exit 127; fi   
	if [ "$ca_dir_name" = "" ]; then
	echo "A CA config directory must be given!"
	$dialog_exe --backtitle "Error" --msgbox "A CA config directory must be given!" 9 52
	exit 4
	fi
else
	ca_confdir_name=$hyp
fi

debug2Syslog "ca_confdir_name $ca_confdir_name"

#Anschließend wird per Dialog der Request präsentiert

openssl req -text -in "${sign_req_name}" -out /tmp/csr.pem

$dialog_exe --backtitle "Certificate Request" --textbox /tmp/csr.pem 0 0

#Nun wird ausgewählt, was für ein Zertifikat erstellt werden soll

#$dialog_exe --backtitle "Info" --msgbox "$ca" 0 0
ca_conf_file=${ca_confdir_name}/${ca}"-ca.conf"
#$dialog_exe --backtitle "Info" --msgbox "$ca_conf_file" 0 0
options=`grep "\[" ${ca_conf_file}|grep _ext|sed 's/\[//g'|sed 's/ //g'|sed 's/\]//g'|sed 's/_ext//g'|sed 's/crl//g'`
#$dialog_exe --backtitle "Info" --msgbox "$options" 0 0
n=0
    for item in ${options}
    do
        menuitems="$menuitems $n ${item}" # subst. Blanks with "_"  
        n=`expr $n + 1`
    done
#    IFS=$IFS_BAK
echo $menuitems
    $dialog_exe --backtitle "Available Types of Certificates" \
           --title "Select one" --menu \
           "Choose one of the available Certificate types" 16 40 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		echo $sel
n=0
    for item in ${options}
    do
#$dialog_exe --msgbox "sel --> $sel\nn --> $n" 6 42
		if [ "$sel" = "$n" ]
		then
        selection=${item} 
		fi
        n=`expr $n + 1`
    done
        debug2Syslog "You choose:\nNo. $sel --> $selection"
	else
		exit 255
    fi
policies=`grep -e "^\[ .*_pol.* \]$" ${ca_conf_file} |sed -E 's/\[ *(.*) *\]/\1/g'`
default_policy=`grep -e "^policy *=.*$" ${ca_conf_file} |sed -E 's/.*= *([^ ]*).*/\1/g'`
menuitems="0 ${default_policy}"  
policy=${default_policy}
n=1
    for item in ${policies}
    do
		if [ "${item}" != "${default_policy}" ]; then
        menuitems="$menuitems $n ${item}" # subst. Blanks with "_"  
        n=`expr $n + 1`
        fi
    done
#    IFS=$IFS_BAK
echo $menuitems
if [ $n -ne 1 ]; then
    $dialog_exe --backtitle "Available Policies for Certificate Creation" \
           --title "Select one" --menu \
           "Choose one of the available Policies" 16 40 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		echo $sel
n=0
    for item in ${policies}
    do
#$dialog_exe --msgbox "sel --> $sel\nn --> $n" 6 42
		if [ "$sel" = "$n" ]
		then
        policy=${item} 
		fi
        n=`expr $n + 1`
    done
        debug2Syslog "You choose:\nNo. $sel --> $policy"
	else
		exit 255
    fi
fi

#Nun wird der Anwender gefragt, ob er den Request signieren möchte

cn=`openssl req -noout -subject -in "${sign_req_name}"| sed -n '/^subject/s/^.*CN\s=\s//p'|cut -d',' -f1`
#$dialog_exe --msgbox "CN: >$cn<" 0 0
#if [ -z "$cn" ]; then
#	$dialog_exe --msgbox "sign_req_name: $sign_req_name" 0 0
#	openssl req -noout -subject -in  "${sign_req_name}" | sed -n '/^subject/s/^.*CN\s=\s//p'>/tmp/te.txt
#	cn=`openssl req -noout -subject -in "${sign_req_name}"| sed -n '/^subject/s/^.*CN\s=\s//p'`
#	$dialog_exe --msgbox "CN1: $cn" 0 0
#fi
debug2Syslog "CN: $cn"
if [ ! -z "$validityInYears" ]; then
  debug2Syslog "found -y $validityInYears"
  validity_in_years="$validityInYears"
  expiration_planned=$(date -d "+$validityInYears years")
  expiration_planned_ts=$(date -d "+$validityInYears years" +%Y%m%d%H%M%S)
  calpreset=$(date -d "+${validity_in_years} years" +"$validityEndDay $validityEndMonth %Y")
#  $dialog_exe --msgbox "$calpreset" 0 0
else
  if [ ! -z "$validityInMonths" ]; then
    debug2Syslog "found -M $validityInMonths"
    expiration_planned=$(date -d "+$validityInMonths months")
    expiration_planned_ts=$(date -d "+$validityInMonths months" +%Y%m%d%H%M%S)
    calpreset=$(date -d "+${validityInMonths} months" +"$validityEndDay %m %Y")
#    $dialog_exe --msgbox "$calpreset" 0 0
  else
#    $dialog_exe --msgbox "no -y or -M" 0 0
    expiration_planned=$(date -d "+3 years")
    expiration_planned_ts=$(date -d "+3 years" +%Y%m%d%H%M%S)
    calpreset=$(date -d "+3 years" +"$validityEndDay $validityEndMonth %Y")
#    $dialog_exe --msgbox "$calpreset" 0 0
  fi
fi

planned_exp=$($dialog_exe --calendar --stdout "Planned expiration" 0 0 ${calpreset})
if [ $? -ne 0 ]; then exit 127; fi   
#expiration_planned_ts=
y=`echo -n "${planned_exp}"|cut -d "/" -f 3`
m=`echo -n "${planned_exp}"|cut -d "/" -f 2`
d=`echo -n "${planned_exp}"|cut -d "/" -f 1`
expiration_planned=$(date -d "${y}-${m}-${d} 23:59:59")
expiration_planned_ts=$(date -d "${y}-${m}-${d} 23:59:59" +%Y%m%d%H%M%S)
expiration_planned_seconds=$(date -d "${y}-${m}-${d} 23:59:59" +%s)

tdir=`dirname ${privkey_file_name}`
ca_cert=`realpath ${tdir}/../../${ca}-ca.crt`
if [ ! -e "$ca_cert" ]; then
ca_cert=`realpath ${tdir}/../../ca/${ca}-ca.crt`
fi
ca_chain=`realpath ${tdir}/../../${ca}-ca-chain.pem`
if [ ! -e "$ca_chain" ]; then
ca_chain=`realpath ${tdir}/../../ca/${ca}-ca-chain.pem`
fi

ca_expiration=`openssl x509 -noout -dates -in ${ca_cert}|grep notAfter|cut -d "=" -f 2`
ca_expiration_ts=$(date -d "${ca_expiration}" +%Y%m%d%H%M%S)
ca_expiration_seconds=$(date -d "${ca_expiration}" +%s)

debug2Syslog "${expiration_planned_ts} ${ca_expiration_ts}" 0 0

if [ "$expiration_planned_seconds" -gt "$ca_expiration_seconds" ]; then
	$dialog_exe --backtitle "Warning" --yesno "CA certificate expiration\n${ca_expiration}\nis reached before planned expiration date for new certificate\n${expiration_planned}\n- is this really what you want?" 0 0 
	if [ $? -eq 1 ]; then 
		exit 6
	fi   
fi

condition=1
while [ $condition -eq 1 ]
do
condition=0
priv_key_pass=$($dialog_exe --stdout --backtitle "Password" --clear --insecure --passwordbox "Please give private key password for\n${ca}!" 0 0)
if [ $? -ne 0 ]; then
exit 255
fi
if [ ${#priv_key_pass} -lt 4 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done

mode="-verbose"
if [ $selection = "root_ca" ]; then
mode="-selfsign"
fi

echo "expect ${script_dir}/sign_csr_dry.xpct ${ca_conf_file}  ${sign_req_name}  certs/${cn}.crt  ${selection} ${expiration_planned_ts} ${priv_key_pass} ${policy} ${mode}">/tmp/stmt.txt

expect "${script_dir}/sign_csr_dry.xpct" "${ca_conf_file}"  "${sign_req_name}"  "certs/${cn}.crt"  "${selection}" "${expiration_planned_ts}" "${priv_key_pass}" "${policy}" "${mode}">/tmp/dry_run.log 2>&1

rv=$?

#$dialog_exe --backtitle "Info" --msgbox "${rv}" 0 0

if [ $rv -ne 0 ]; then
cat /tmp/dry_run.log |sed $'s/\r$//' |tail -n +5>/tmp/dry_run1.log

tailed=$(cat /tmp/dry_run1.log|tail)

$dialog_exe --backtitle "Unable to sign certificate request" --yesno "${tailed}\n\nDo you want to see the full log?" 20 80
response=$?
if [ $response -eq 0 ]; then
$dialog_exe --backtitle "Unable to sign certificate request" --textbox /tmp/dry_run1.log 0 0
fi
else

cat /tmp/dry_run.log|sed $'s/\r$//' |tail -n +6|head -n -1 >/tmp/dry_run1.log
$dialog_exe --backtitle "Certificate Dry Run" --textbox /tmp/dry_run1.log 0 0

$dialog_exe --backtitle "Decision" --yesno "Do You want to sign this request\nfrom ${cn}\nand create the associated certificate?" 0 0
if [ $? -eq 0 ]; then

# output der Daten in eine tsv-Datei
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
log_file_name=$($dialog_exe --stdout --backtitle "Log" --fselect "./${cn}_${timestamp}_log.tsv" $(expr $(tput lines) - 12 ) $(expr $(tput cols) - 10 ))
if [ ${?} -ne 0 ]; then exit 127; fi   
#if [ "$log_file_name" = "" ]; then
#echo "A log file name must be given!"
#$dialog_exe --backtitle "Error" --msgbox "A log file name must be given!" 9 52
#exit 4
#fi

#Anschließend wird der Request per Openssl signiert

expect "${script_dir}/sign_csr.xpct" "${ca_conf_file}"  "${sign_req_name}"  "certs/${cn}.crt"  "${selection}" "${expiration_planned_ts}" "${priv_key_pass}" "${policy}" "${mode}"

priv_key_pass=""

#openssl ca \
#    -config ${ca_conf_file} \
#    -in ${sign_req_name} \
#    -out ca/${cn}.crt \
#    -extensions ${selection}_ext \
#    -enddate ${expiration_planned_ts}Z

#Der Anwender wird darüber informiert,
#dass er die "Deliverables" 
# * CA-Zertifikat
# * falls existiert: Zertifikatskette
# * ausgestelltes Zertifikat
#an denjenigen Zurücksenden kann, von dem der Request stammte.
serial=`openssl x509 -noout -serial -in "certs/${cn}.crt" |cut -d "=" -f 2`
expiration=`openssl x509 -noout -dates -in "certs/${cn}.crt" |grep notAfter|cut -d "=" -f 2`
start=`openssl x509 -noout -dates -in "certs/${cn}.crt" |grep notBefore|cut -d "=" -f 2`
#startn=`openssl x509 -noout -dates -in "certs/${cn}.crt" | grep notBefore | sed -e 's#notBefore=##'`
#startts=`date -d "${data}" '+%Y.%m.%d-%H.%M.%S'`
startts=`date '+%Y.%m.%d-%H.%M.%S'`
openssl x509 -inform PEM -outform DER -in "certs/${cn}.crt" -out "certs/${cn}.der"

#infomsg
$dialog_exe --backtitle "Info (scroll with PgUp, PgDown)" --msgbox "The issuer certificate is in issuer.crt\nThe certificate is in certs/${startts}_${cn}.crt (PEM) and in certs/${startts}_${cn}.der (DER)\nThe certificate will expire on ${expiration}\n\nYou can now send the archive\ndeliverables_${cn}_${timestamp}.zip\nback to the requestor!" 0 0

# eventuell sogar zip/tar draus machen?

mkdir -p "${cn}"
if [ -e "$ca_chain" ]; then
ca_cert=${ca_chain}
fi
echo "issuer=\"${cn}/issuer.crt\"" >index.txt
cp ${ca_cert} "${cn}/issuer.crt"
echo "zert (single)=\"${cn}/${cn}_single.crt\"" >>index.txt
cp "certs/${cn}.crt" "${cn}/${cn}_single.crt"
echo "zert (chained)=\"${cn}/${cn}.crt\"" >>index.txt
cat "certs/${cn}.crt" "${ca_chain}" >"${cn}/${cn}.crt"
echo "zert (single) DER=\"${cn}/${cn}.der\"" >>index.txt
cp "certs/${cn}.der" "${cn}/"
if [ $selection = "timestamp" ]; then
#$dialog_exe --backtitle "Info" --msgbox "copying ${ca_chain} to ${cn}/chain.pem" 0 0
echo "chain=\"${cn}/chain.pem\"" >>index.txt
cp "${ca_chain}" "${cn}/chain.pem"
echo "tsa.conf=\"${cn}/tsa.conf\"" >>index.txt
cp "${script_dir}"/templates/tsa.conf  "${cn}"
sed -i -- "s/##crt##/${cn}.crt/g" "${cn}"/tsa.conf
else
cp "../build_p12.sh" "${cn}/"
fi
zip "deliverables_${cn}_${timestamp}.zip" "${cn}"/* index.txt
#rm -rf "deliverables_${cn}"

mv "certs/${cn}.crt" "certs/${startts}_${cn}.crt"
mv "certs/${cn}.der" "certs/${startts}_${cn}.der"

#log schreiben: minimum: aktuelles Datum, Ende-Datum, Serien-Nummer, Subject
if [ "$log_file_name" != "" ]; then
echo -e "CN\tcert file\tissuer cert file\tnotBefore\tnotAfter" > "${log_file_name}"
echo -e "${cn}\tcerts/${startts}_${cn}.crt\tcerts/${startts}_${cn}.der\t${ca_cert}\t${start}\t${expiration}" >> "${log_file_name}"
chmod 600 "${log_file_name}"
if [ -d "$cn" ]; then
  rm -rf "${cn}"
fi
#infomsg
$dialog_exe --backtitle "Info" --msgbox "log file written to ${log_file_name}" 0 0
fi

fi
fi
clear
