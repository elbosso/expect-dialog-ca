#!/bin/sh
#Das Script soll online und offline funktionieren
#es kopiert aus einem Musterverzeichnis (der openssl expert pki)
#die am besten passenden Dateien in ein neu anzulegendes Verzeichnis und passt diese Templates
#anschließend entsprechend der Nutzereingaben an.
#dazu wird (im online-Fall) 
# * git benötigt, 
#sowie (im offline-Fall)
# * ein bestehendes Verzeichnis mit den Dateien der Expert-PKI
printHelp ()
{
echo "usage: $0 [-t <offline template dir>] [-k pre-existing key file] [-h]"
}
dialog_exe=dialog
. ./configure_gui.sh
optionerror=0
offline_template_dir=""
preexisting_key_file=""
_temp="/tmp/answer.$$"
while getopts ":t:k:h" opt; do
  case "$opt" in
    t)
#      echo "-t was triggered! ($OPTARG)" >&2
		offline_template_dir="$OPTARG"
      ;;
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		preexisting_key_file=$OPTARG
		if [ ! -e "$preexisting_key_file" ]; then
			"$dialog_exe" --backtitle "Error:" --msgbox "$preexisting_key_file does not exist!" 9 52
		exit 122
		fi
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

#echo $offline_template_dir
#zunächst wird gecheckt, ob die Variable offline_template_dir gesetzt ist
#falls ja wird template_dir deren Wert zugewiesen
#falls nicht, wird versucht, die expert-pki auszuchecken und template_dir wird 
#auf den Namen des ausgecheckten Verzeichnisses gesetzt
if [ "$offline_template_dir" != "" ]
then
	template_dir="$offline_template_dir"
else
	command -v git
	gitpresent="$?"
	if [ "$gitpresent" != 0 ]; then
		echo "git not present!"
		exit 1
    fi
	if [ -d "./__template__" ]; then
		rm -rf ./__template__
	fi
	git clone https://bitbucket.org/stefanholek/pki-example-3 __template__
	template_dir=./__template__
fi
echo "$template_dir"

if [ -d "$template_dir" ]; then
	if [ ! "$(ls -A $template_dir)" ]; then
		exit 1
	fi
fi

#nun wird versucht, herauszufinden, was alles für template cas vorliegen
cd "$template_dir"/etc
ca_templates=$(ls ./*ca.conf)
cd -
echo "$ca_templates"

#daraus wird ein Dialog gebaut, der die Möglichkeiten anzeigt und der Anwender kann dann per 
#Radiobuttons eine daraus auswählen
n=0
    for item in ${ca_templates}
    do
		if [ "$item" != "root-ca.conf" ]
		then
        menuitems="$menuitems $n ${item}" # subst. Blanks with "_"  
        n=$(expr $n + 1)
		fi
    done
#    IFS=$IFS_BAK
echo "$menuitems"
    "$dialog_exe" --backtitle "Available Types of CAs" \
           --title "Select one" --menu \
           "Choose one of the available CA types" 16 40 8 "$menuitems" 2> "$_temp"
    if [ "$?" -eq 0 ]; then
         sel=$(cat "$_temp")
		echo "$sel"
n=0
    for item in ${ca_templates}
    do
#$dialog_exe --msgbox "sel --> $sel\nn --> $n" 6 42
		if [ "$sel" = "$n" ]
		then
        selection=${item} 
		fi
        n=$(expr "$n" + 1)
    done
#        $dialog_exe --msgbox "You choose:\nNo. $sel --> $selection" 6 42
	else
		exit 255
    fi
ca_type=$(echo -n "$selection" |cut -d - -f 1)
#$dialog_exe --msgbox "type --> $ca_type" 6 42

#Der Anwender wird aufgefordert, den Namen der neuen CA zu bestimmen
"$dialog_exe" --backtitle "CA name"\
           --inputbox "Name for the new CA" 8 52 "test" 2>$_temp

    if [ "$?" -eq 0 ]; then
    new_ca_name=$(cat "$_temp")
#    $dialog_exe --msgbox "\nYou entered:\n$new_ca_name" 9 52
if [ "$new_ca_name" = "" ]; then
echo "You must provide a name!"
"$dialog_exe" --backtitle "Error" \
           --msgbox "You must provide a name!" 9 52
exit 2
fi
	else
		exit 255
    fi

#Mit diesem Namen wird ein Verzeichnis angelegt
mkdir -p "$new_ca_name"

#In diesem Verzeichnis wird die Infrastruktur der neuen CA angelegt (Verzeihcnisse, Serials, DB, Attributes,etc,...)
mkdir -p "$new_ca_name"/ca/private "$new_ca_name"/ca/db "$new_ca_name"/crl "$new_ca_name"/certs
chmod 700 "$new_ca_name"/ca/private
cp /dev/null "$new_ca_name"/ca/db/"$new_ca_name"-ca.db
cp /dev/null "$new_ca_name"/ca/db/"$new_ca_name"-ca.db.attr
echo 01 > "$new_ca_name"/ca/db/"$new_ca_name"-ca.crt.srl
echo 01 > "$new_ca_name"/ca/db/"$new_ca_name"-ca.crl.srl


#Nun werden aus dem Template die passenden Dateien in das Verzeichnis der neuen CA kopiert.

mkdir -p "$new_ca_name"/etc
chmod 700 "$new_ca_name"/etc
cp -a "$template_dir"/etc/"$ca_type"-ca.conf "$new_ca_name"/etc/"$new_ca_name"-ca.conf
case "$ca_type" in
    component)
      cp -a "$template_dir"/etc/ocspsign.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/server.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/timestamp.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/client.conf "$new_ca_name"/etc
      ;;
    network)
      cp -a "$template_dir"/etc/identity-ca.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/component-ca.conf "$new_ca_name"/etc
#      cp -a "$template_dir"/etc/.conf "$new_ca_name"/etc
#      cp -a "$template_dir"/etc/.conf "$new_ca_name"/etc
      ;;
	identity)
      cp -a "$template_dir"/etc/identity.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/encryption.conf "$new_ca_name"/etc
      cp -a "$template_dir"/etc/identity.conf "$new_ca_name"/etc/smime.conf
#Hier werden die Voraussetzungen geschaffen, dass man auch auf einfache Weise S/MIME-Zertifikate erstellen kann
#(mit dieser DI kann man dann EMails sowohl verschlüsseln als auch signieren!)
	  sed -i -- "s/identity/smime/g"  "$new_ca_name"/etc/smime.conf
	  sed -i -- "s/Identity/S\/MIME/g"  "$new_ca_name"/etc/smime.conf
	  sed -i -E -- "s/keyUsage(.*)/keyUsage\1,keyEncipherment/g"  "$new_ca_name"/etc/smime.conf
		echo "" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "[ smime_ext ]" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "keyUsage                = critical,keyEncipherment,digitalSignature" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "basicConstraints        = CA:false" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "extendedKeyUsage        = emailProtection,msEFS,clientAuth,msSmartcardLogin" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "subjectKeyIdentifier    = hash" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "authorityKeyIdentifier  = keyid:always" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "authorityInfoAccess     = @issuer_info" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf
		echo "crlDistributionPoints   = @crl_info" >>"$new_ca_name"/etc/"$new_ca_name"-ca.conf

#      cp -a "$template_dir"/etc/.conf "$new_ca_name"/etc
#      cp -a "$template_dir"/etc/.conf "$new_ca_name"/etc
      ;;
  esac

#Anschließend wird in den kopierten Dateien der Name der CA durch den vom Nutzer gewählten ersetzt
#$dialog_exe --backtitle "Info" --msgbox "s/${ca_type}-ca/${new_ca_name}-ca/g\n$new_ca_name/etc/$ca_type"-ca.conf"" 9 52

sed -i -- "s/${ca_type}-ca/${new_ca_name}-ca/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/${ca_type}_ca/${new_ca_name}_ca/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf

#An den Policies wird ein wenig herumgefeilt
sed -i -E -- "s/(countryName *= *)match(.*)/\1supplied\2/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/match_pol/match_O_pol/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -E -- "s/(commonName *= *)optional(.*)/\1supplied\2/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/any_pol/minimal_pol/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf

condition=1
while [ "$condition" -eq 1 ]
do
condition=0
"$dialog_exe" --backtitle "CA configuration" \
	    --form " Please give some information - use [up] [down] to select input field " 0 0 0 \
	    "countryName" 2 4 "DE" 2 25 40 0\
	    "organizationName" 4 4 "" 4 25 40 0\
	    "organizationalUnitName" 6 4 "" 6 25 40 0\
	    "base_url" 8 4 "http://" 8 25 40 0\
	    2>$_temp
	
	if [ ${?} -ne 0 ]; then exit 127; fi
    result=$(cat "$_temp")
    echo "Result=$result"
#    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
countryName=$(cat "$_temp" |cut -d"
" -f 1)
organizationName=$(cat "$_temp" |cut -d"
" -f 2)
organizationalUnitName=$(cat "$_temp" |cut -d"
" -f 3)
base_url=$(cat "$_temp" |cut -d"
" -f 4)
if [ "$countryName" = "" ] || [ "$organizationName" = "" ] || [ "$organizationalUnitName" = "" ] || [ "$base_url" = "" ]; then
echo "You must fill out all the fields!"
"$dialog_exe" --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
done

arg=$(echo -n "s/organizationalUnitName  = \".*?\"/organizationalUnitName  = \"${organizationalUnitName}\"/g")
#$dialog_exe --backtitle "Info" --msgbox "$arg" 9 52
sed -i -- "s/# Blue Component CA.*/# ${organizationalUnitName}/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s|base_url *= .*|base_url = ${base_url}|g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/countryName *= \".*\"/countryName = \"${countryName}\"/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/organizationName *= \".*\"/organizationName = \"${organizationName}\"/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/organizationalUnitName *= \".*\"/organizationalUnitName  = \"${organizationalUnitName}\"/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- "s/commonName *= \".*\"/commonName  = \"${organizationalUnitName}\"/g"  "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- 's/certificatePolicies/#certificatePolicies/g' "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- 's_$dir/ca/$ca_$dir/ca_g' "$new_ca_name"/etc/"$new_ca_name"-ca.conf
sed -i -- 's_$dir/ca.crt_$dir/ca/$ca.crt_g' "$new_ca_name"/etc/"$new_ca_name"-ca.conf

#Die Schlüssellänge und der zu benutzende Hash-Algorithmus werden festgelegt
"$dialog_exe" --backtitle "Available key lengths" \
           --title "Select one" --radiolist \
			"Choose one of the available key lengths" 16 40 8 \
			1 1024 off\
			2 2048 off\
			3 4096 on\
			2> $_temp
    if [ "$?" -eq 0 ]; then
         sel=$(cat "$_temp")
		case "$sel" in
			1)
				key_length="1024"
				;;
			2)
				key_length="2048"
				;;
			*)
				key_length="4096"
				;;
		esac
	else
		exit 255
    fi
"$dialog_exe" --backtitle "Available hash algorithms" \
           --title "Select one" --radiolist \
			"Choose one of the available hash algorithms" 16 40 8\
			1 MD5 off\
			2 SHA-1 off\
			3 SHA-224 off\
			4 SHA-256 on\
			5 SHA-348 off\
			6 SHA-512 off\
			2> $_temp
    if [ "$?" -eq 0 ]; then
         sel=$(cat "$_temp")
		case "$sel" in
			1)
				hash_alg="md5"
				;;
			2)
				hash_alg="sha1"
				;;
			3)
				hash_alg="sha224"
				;;
			5)
				hash_alg="sha348"
				;;
			6)
				hash_alg="sha512"
				;;
			*)
				hash_alg="sha256"
				;;
		esac
	else
		exit 255
    fi
sed -i -E -- "s/(default_md *= *)sha1(.*)/\1$hash_alg\2/g"  "$new_ca_name"/etc/*.conf
sed -i -E -- "s/(default_bits *= *)2048(.*)/\1$key_length\2/g"  "$new_ca_name"/etc/*.conf


#Die Konfiguration der CA wird festgelegt: Welche Angaben müssen in einem Request enthalten sein und 
#Welche der Angaben  müssen bestimmten Vorgaben genügen.

#Welche Defaults sollen das Erstellen eines CSR erleichtern?
conf_files=$(find "$new_ca_name"/etc/ -maxdepth 1 ! -name '*ca.conf' ! -name '.'|rev|cut -d / -f 1|rev)
for item in ${conf_files}
    do
"$dialog_exe" --backtitle "CSR defaults for $item" \
	    --form " Specify defaults for $item - use [up] [down] to select input field " 0 0 0 \
	    "countryName" 2 4 "DE" 2 25 40 0\
	    "stateOrProvinceName" 4 4 "" 4 25 40 0\
	    "localityName" 6 4 "" 6 25 40 0\
	    "organizationName" 8 4 "" 8 25 40 0\
	    "organizationalUnitName" 10 4 "" 10 25 40 0\
	    "commonName" 12 4 "" 12 25 64 0\
	    "emailAddress" 14 4 "" 14 25 40 0\
	    2>$_temp
	
	if [ ${?} -ne 0 ]; then exit 127; fi   
    result=$(cat "$_temp")
    echo "Result=$result"
#    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
countryName=$(cat "$_temp" |cut -d"
" -f 1)
stateOrProvinceName=$(cat "$_temp" |cut -d"
" -f 2)
localityName=$(cat "$_temp" |cut -d"
" -f 3)
organizationName=$(cat "$_temp" |cut -d"
" -f 4)
organizationalUnitName=$(cat "$_temp" |cut -d"
" -f 5)
commonName=$(cat "$_temp" |cut -d"
" -f 6)
emailAddress=$(cat "$_temp" |cut -d"
" -f 7)
if [ ! "$countryName" = "" ]; then
sed -i -E -- "/countryName *=.*/a countryName_default = \"$countryName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$stateOrProvinceName" = "" ]; then
sed -i -E -- "/stateOrProvinceName *=.*/a stateOrProvinceName_default = \"$stateOrProvinceName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$localityName" = "" ]; then
sed -i -E -- "/localityName *=.*/a localityName_default = \"$localityName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$organizationName" = "" ]; then
sed -i -E -- "/organizationName *=.*/a organizationName_default = \"$organizationName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$organizationalUnitName" = "" ]; then
sed -i -E -- "/organizationalUnitName *=.*/a organizationalUnitName_default = \"$organizationalUnitName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$commonName" = "" ]; then
sed -i -E -- "/commonName *=.*/a commonName_default = \"$commonName\""  "$new_ca_name"/etc/"$item"
fi
if [ ! "$emailAddress" = "" ]; then
sed -i -E -- "/emailAddress *=.*/a emailAddress_default = \"$emailAddress\""  "$new_ca_name"/etc/"$item"
fi

    done

proposed_pass=$(makepasswd -count 1 -minchars 8)
condition=1
if [ "$preexisting_key_file" = "" ]; then
while [ "$condition" -eq 1 ]
do
condition=0
result=$("$dialog_exe" --stdout --backtitle "Password for private key" \
	    --form " Please specify - use [up] [down] to select input field " 0 0 0 \
	    "Password" 2 4 "$proposed_pass" 2 25 40 0\
	    "Verification" 4 4 "" 4 25 40 0)
	
	if [ ${?} -ne 0 ]; then exit 127; fi   
#    result=$(cat $_temp)
    echo "Result=$result"

Password=$(echo "$result"|cut -d"
" -f 1)
Verification=$(echo "$result" |cut -d"
" -f 2)
#$dialog_exe --backtitle "Info" --msgbox "$result\n--\n$Password\n$Verification" 9 52
if [ "$Password" = "" ] || [ "$Verification" = "" ]; then
echo "You must fill out all the fields!"
"$dialog_exe" --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
if [ "$Verification" != "$Password" ] && [ "$condition" -eq 0 ]; then
echo "Password and verification differ!"
"$dialog_exe" --backtitle "Error" --msgbox "You must fill out all the fields identically!" 9 52
condition=1
fi
if [ ${#Password} -lt 4 ] && [ "$condition" -eq 0 ]; then
"$dialog_exe" --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done
else
while [ "$condition" -eq 1 ]
do
result=$("$dialog_exe" --stdout --backtitle "Password for private key" \
	    --form " Please specify - use [up] [down] to select input field " 0 0 0 \
	    "Password" 2 4 "" 2 25 40 0)
	
	if [ ${?} -ne 0 ]; then exit 127; fi   
#    result=$(cat $_temp)
    echo "Result=$result"
Password=$(echo "$result"|cut -d"
" -f 1)
if [ "$Password" = "" ]; then
echo "You must give a password!"
"$dialog_exe" --backtitle "Error" --msgbox "You must give a password!" 9 52
condition=1
fi
done
fi
# output der Daten in eine tsv-Datei

log_file_name=$("$dialog_exe" --stdout --backtitle "Log" --fselect ./${new_ca_name}_log.tsv 0 0)
if [ ${?} -ne 0 ]; then exit 127; fi   
#if [ "$log_file_name" = "" ]; then
#echo "A log file name must be given!"
#$dialog_exe --backtitle "Error" --msgbox "A log file name must be given!" 9 52
#exit 4
#fi

#Ein privater Schlüssel wird für die CA erzeugt

#openssl req -new \
#    -config $new_ca_name/etc/$new_ca_name"-ca.conf" \
#    -out $new_ca_name/${new_ca_name}-ca.csr \
#    -keyout $new_ca_name/private/$new_ca_name"-ca.key"

if [ "$preexisting_key_file" = "" ]; then
expect ca_csr.xpct ${new_ca_name} $Password
else
cp "$preexisting_key_file" ${new_ca_name}/ca/private/${new_ca_name}-ca.key
expect ca_csr_with_key.xpct ${new_ca_name} "$Password" "$preexisting_key_file"
fi
#Der Anwender wird per $dialog_exe darüber informiert, dass er dem Zertifikatsrequest bei der CA, von der die Konfiguration stammte,
#einreichen kann.

openssl req -text -in ${new_ca_name}/ca/${new_ca_name}-ca.csr -out /tmp/csr.pem

"$dialog_exe" --backtitle "Certificate Request" --textbox /tmp/csr.pem 0 0

"$dialog_exe" --backtitle "Info" --msgbox "The key is in ${new_ca_name}/ca/private/${new_ca_name}-ca.key\nThe Cert Req is in ${new_ca_name}/ca/${new_ca_name}-ca.csr\n\nYou can now ask your CA to sign the request!\n\nThe configurations needed by clients to generate certificate signing requests are in ${new_ca_name}/ca/etc. Available are: $conf_files" 16 52

"$dialog_exe" --backtitle "Custom Policies" --msgbox "At this time, two policies are defined in the CA configuration file $new_ca_name/etc/$new_ca_name-ca.conf. If you want to add more or add some of your own - feel free to add them using the one named minimal_pol as a template. You are free when naming them but if the names do not end with _pol, the script for signing CSRs will not pick them up so you will not be able to use them when actually signing CSRs!" 14 64

#log schreiben

if [ "$log_file_name" != "" ]; then
echo "name\tCN\tprivate key pass" > ${log_file_name}
echo "${new_ca_name}\t${organizationalUnitName}\t${Password}" >> ${log_file_name}
chmod 600 ${log_file_name}
"$dialog_exe" --backtitle "Info" --msgbox "log file written to ${log_file_name}" 0 0
fi

#am Ende wird gecheckt, ob die Variable offline_template_dir gesetzt war
#falls nicht, wird versucht, die ausgecheckte expert-pki  
#wieder zu löschen
if [ "$offline_template_dir" = "" ]
then
	rm -rf __template__
fi
clear
