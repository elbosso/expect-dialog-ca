#!/bin/sh
# shellcheck disable=SC2181,SC2003,SC2039,SC2002
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
echo "usage: $0 [-t <offline template dir>] [-k <pre-existing key file>] [-c <type of CA>] [-n <name of CA>] [-l <key length>] [-a <hash algorithm>] [-p] [-o] [-g] [-h]"
echo ""
echo "https://elbosso.github.io/expect-dialog-ca/"
echo ""
echo "-t <offline template dir>\tThe script initially tries to download the\n\t\texpert pki unless this parameter specifies an already\n\t\tdownloaded version\n"
echo "-k <pre-existing key file>\tA key pair is created for the new CA unless\n\t\tthere is already a preexisting key file - in this case,\n\t\tit has to be specified here\n"
echo "-c <type of CA>\t\tThe script skips the dialog for choosing\n\t\tthe type of CA about to be created if the value given\n\t\there is one of the types offered by the expert PKI\n\t\tproject (at the time of writing these are:\n\t\troot|component|network|identity|software)\n"
echo "-n <name of CA>\t\tThe name of the CA about to be created.\n\t\tThis skips the dialog asking vor it. The name must not\n\t\tcontain special characters such as whitespace or umlaute etc.\n"
echo "-l <key length>\t\tThe length in bits of the key to be\n\t\tcreated (if no preexisting key is given, see above).\n\t\tIf this value is given here as one of the supported values\n\t\t1024|2048|4096 the corresponding dialog is skipped.\n"
echo "-a <hash algorithm>\t\tThe message digest algorithm to be used.\n\t\tIf this value is given here as one of the supported values\n\t\tmd5|sha1|sha224|sha348|sha512|sha256 the corresponding dialog\n\t\tis skipped.\n"
echo "-p\t\tSkip specification of CPS\n"
echo "-o\t\tSkip specification of custom OIDs\n"
echo "-g\t\tGenerate template for ca_presets.ini and stop execution\n\t\tafterwards\n"
echo "-h\t\tPrint this help text\n"
#echo ""
}
dialog_exe=dialog
. ./configure_gui.sh
optionerror=0
offline_template_dir=""
preexisting_key_file=""
_temp="/tmp/answer.$$"
while getopts ":t:k:c:n:l:a:opgh" opt; do
  case $opt in
    t)
#      echo "-t was triggered! ($OPTARG)" >&2
		offline_template_dir=$OPTARG
      ;;
    k)
#      echo "-k was triggered! ($OPTARG)" >&2
		preexisting_key_file=$OPTARG
		if [ ! -e "$preexisting_key_file" ]; then
			$dialog_exe --backtitle "Error:" --msgbox "$preexisting_key_file does not exist!" 9 52
		exit 122
		fi
      ;;
    c)
#      echo "-t was triggered! ($OPTARG)" >&2
		wanted_ca_type=$OPTARG
      ;;
    n)
#      echo "-t was triggered! ($OPTARG)" >&2
		new_ca_name_param=$OPTARG
      ;;
    l)
      case $OPTARG in
        1024)
          key_length="1024"
          ;;
        2048)
          key_length="2048"
          ;;
        4096)
          key_length="4096"
          ;;
      esac
      ;;
    a)
      case $OPTARG in
        md5)
          hash_alg="md5"
          ;;
        sha1)
          hash_alg="sha1"
          ;;
        sha224)
          hash_alg="sha224"
          ;;
        sha348)
          hash_alg="sha348"
          ;;
        sha512)
          hash_alg="sha512"
          ;;
        sha256)
          hash_alg="sha256"
          ;;
      esac
      ;;
    h)
	  printHelp
      exit 0
	  ;;
    o)
      no_custom_oids=true
	  ;;
    p)
      no_cpss=true
	  ;;
    g)
      if [ -e ca_presets.ini ]; then
        $dialog_exe --backtitle "Error:" --msgbox "ca_presets.ini does already exist - not overwriting it!" 9 52
      else
        echo "#used for the subject data and for the default values for config items in end user configs" >ca_presets.ini
        echo "countryName=\"\"" >>ca_presets.ini
        echo "#used for the subject data and for the default values for config items in end user configs" >>ca_presets.ini
        echo "organizationName=\"\"" >>ca_presets.ini
        echo "#used for the subject data and for the default values for config items in end user configs" >>ca_presets.ini
        echo "organizationalUnitName=\"\"" >>ca_presets.ini
        echo "#used for the subject data" >>ca_presets.ini
        echo "commonName=\"\"" >>ca_presets.ini
        echo "#used for the configuration of the CA - everywhere where an URL is needed; for example location of CA certificate, CRL,..." >>ca_presets.ini
        echo "base_url=\"\"" >>ca_presets.ini
        echo "#used in end user configs" >>ca_presets.ini
        echo "stateOrProvinceName=\"\"" >>ca_presets.ini
        echo "#used in end user configs" >>ca_presets.ini
        echo "localityName=\"\"" >>ca_presets.ini
        $dialog_exe --backtitle "Success:" --msgbox "Wrote template ca_presets.ini!" 9 52
      fi
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
	template_dir=$offline_template_dir
else
	command -v git
	gitpresent=$?
	if [ "$gitpresent" != 0 ]; then
		echo "git not present!"
		exit 1
    fi
	if [ -d "./__template__" ]; then
		rm -rf ./__template__
	fi
	git clone https://bitbucket.org/stefanholek/pki-example-3 __template__
	template_dir=./__template__
	cp "templates/software-ca.conf" "$template_dir/etc"
fi
echo $template_dir

if [ -d "$template_dir" ]; then
	if [ ! "$(ls -A $template_dir)" ]; then
		exit 1
	fi
fi

#nun wird versucht, herauszufinden, was alles für template cas vorliegen
cd $template_dir/etc || exit
ca_templates=$(ls *ca.conf)
cd - || exit
echo "$ca_templates"

#daraus wird ein Dialog gebaut, der die Möglichkeiten anzeigt und der Anwender kann dann per 
#Radiobuttons eine daraus auswählen
n=0
    for item in ${ca_templates}
    do
      if [ ! -z ${wanted_ca_type+x} ]; then
        if [ ${item#$wanted_ca_type} != $item ]; then
          ca_type="$wanted_ca_type"
        fi
      fi
#		if [ "$item" != "root-ca.conf" ]
#		then
        menuitems="$menuitems $n ${item}" # subst. Blanks with "_"  
        n=$(expr $n + 1)
#		fi
    done
#    IFS=$IFS_BAK
echo "$menuitems"
if [ -z ${ca_type+x} ]; then
    $dialog_exe --backtitle "Available Types of CAs" \
           --title "Select one" --menu \
           "Choose one of the available CA types" 16 40 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
         sel=$(cat $_temp)
		echo "$sel"
n=0
    for item in $ca_templates
    do
#$dialog_exe --msgbox "sel --> $sel\nn --> $n" 6 42
		if [ "$sel" = "$n" ]
		then
        selection=${item} 
		fi
        n=$(expr $n + 1)
    done
#        $dialog_exe --msgbox "You choose:\nNo. $sel --> $selection" 6 42
	else
		exit 255
    fi
ca_type=$(echo -n "$selection" |cut -d - -f 1)
#$dialog_exe --msgbox "type --> $ca_type" 6 42
fi

condition=1
error=0
while [ $condition -eq 1 ]
do
condition=0
if [ -z ${new_ca_name_param+x} ] || [ $error -eq "1" ]; then
#Der Anwender wird aufgefordert, den Namen der neuen CA zu bestimmen
$dialog_exe --backtitle "CA name"\
           --inputbox "Name for the new CA\n Please do not use root, network, identity, or component!" 8 52 "${new_ca_name:-test}" 2>$_temp

    if [ $? -eq 0 ]; then
    new_ca_name=$(cat $_temp)
#    $dialog_exe --msgbox "\nYou entered:\n$new_ca_name" 9 52
    else
      exit 255
    fi
else
    new_ca_name=$new_ca_name_param
fi
if [ ! -z ${new_ca_name+x} ]; then
if [ "$new_ca_name" = "" ]; then
echo "You must provide a name!"
$dialog_exe --backtitle "Error" \
           --msgbox "You must provide a name!" 9 52
condition=1
error="1"
else
case "$new_ca_name" in
   root|network|identity|component)
     $dialog_exe --backtitle "Error" \
           --msgbox "The name must not be among these reserved values: root, network, identity, component!" 9 52
     condition=1
     error="1";;
   *)
     ;;
esac
fi
	else
	  echo $new_ca_name_param $new_ca_name
		exit 254
    fi
done


if [ -e "$new_ca_name" ]; then
  $dialog_exe --backtitle "Error" \
           --msgbox "There already is a file or directory with the name $new_ca_name - aborting!" 0 0
  exit 253
fi
#Mit diesem Namen wird ein Verzeichnis angelegt
mkdir -p "$new_ca_name"

#In diesem Verzeichnis wird die Infrastruktur der neuen CA angelegt (Verzeihcnisse, Serials, DB, Attributes,etc,...)
mkdir -p "$new_ca_name/ca/private" "$new_ca_name/ca/db" "$new_ca_name/crl" "$new_ca_name/certs"
chmod 700 "$new_ca_name/ca/private"
cp /dev/null "$new_ca_name/ca/db/$new_ca_name-ca.db"
cp /dev/null "$new_ca_name/ca/db/$new_ca_name-ca.db.attr"
echo 01 > "$new_ca_name/ca/db/$new_ca_name-ca.crt.srl"
echo 01 > "$new_ca_name/ca/db/$new_ca_name-ca.crl.srl"


#Nun werden aus dem Template die passenden Dateien in das Verzeichnis der neuen CA kopiert.

mkdir -p "$new_ca_name/etc"
chmod 700 "$new_ca_name/etc"
#cp -a $template_dir/etc/$ca_type"-ca.conf" $new_ca_name/etc/$new_ca_name"-ca.conf"
cat $template_dir/etc/$ca_type"-ca.conf" | head -n -3 >$new_ca_name/etc/$new_ca_name"-ca.conf"

case $ca_type in
    component)
      cp -a "$template_dir/etc/ocspsign.conf" "$new_ca_name/etc"
      cp -a "$template_dir/etc/server.conf" "$new_ca_name/etc"
      #cp -a "$template_dir/etc/timestamp.conf" "$new_ca_name/etc"
      awk '/\[ timestamp_reqext \]/ || f == 1 && sub(/keyUsage                = critical,digitalSignature/, "keyUsage                = critical,nonRepudiation") { ++f } 1' $template_dir/etc/timestamp.conf >$new_ca_name/etc/timestamp.conf.intermediate
      mv $new_ca_name/etc/timestamp.conf.intermediate $new_ca_name/etc/timestamp.conf
      cp -a "$template_dir/etc/client.conf" "$new_ca_name/etc"
      awk '/\[ server_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumDevice/, "#certificatePolicies = serverCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ client_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumDevice/, "#certificatePolicies = clientCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ timestamp_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumDevice/, "#certificatePolicies = timestampCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ timestamp_ext \]/ || f == 1 && sub(/keyUsage                = critical,digitalSignature/, "keyUsage                = critical,nonRepudiation") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ ocspsign_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumDevice/, "#certificatePolicies = ocspsignCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      ;;
    network)
      cp -a $template_dir/etc/"identity-ca.conf" $new_ca_name/etc
      cp -a $template_dir/etc/"component-ca.conf" $new_ca_name/etc
#      cp -a $template_dir/etc/".conf" $new_ca_name/etc
#      cp -a $template_dir/etc/".conf" $new_ca_name/etc
	  sed -ie -- "s/basicConstraints *= critical,CA:true$/basicConstraints        = critical,CA:true,pathlen:1/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
#	  i confess i do not know why this is: the options to the sed call above have exactly to be as is given there -
# "-e -i" works not, neither does "-i -e" or "-ei"
# the call works but for reasons unknown to man it creates a file i dont want to have so i have to remove it afterwards
# that is what the next line is for:
      rm $new_ca_name/etc/$new_ca_name"-ca.confe"
	  sed -n "/\[ signing_ca_ext \]/,/^$/p" $new_ca_name/etc/$new_ca_name"-ca.conf">/tmp/tt
	  sed -i -- "s/\[ signing_ca_ext \]/\[ identity_ca_ext \]/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "" >> $new_ca_name/etc/$new_ca_name"-ca.conf"
	  cat /tmp/tt >> $new_ca_name/etc/$new_ca_name"-ca.conf"
	  sed -i -- "s/\[ signing_ca_ext \]/\[ component_ca_ext \]/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
 	  echo "" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "[ software_ca_ext ]" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "keyUsage                = critical,keyCertSign,cRLSign" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "basicConstraints        = critical,CA:true,pathlen:0" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "subjectKeyIdentifier    = hash" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "authorityKeyIdentifier  = keyid:always" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "authorityInfoAccess     = @issuer_info" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "crlDistributionPoints   = @crl_info" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  echo "#certificatePolicies = softwareCPS" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
     awk '/\[ identity_ca_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance,blueMediumDevice/, "#certificatePolicies = identityCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ intermediate_ca_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance,blueMediumDevice/, "#certificatePolicies = intermediateCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ component_ca_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance,blueMediumDevice/, "#certificatePolicies = componentCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      ;;
	identity)
      cp -a $template_dir/etc/"identity.conf" $new_ca_name/etc
      cp -a $template_dir/etc/"encryption.conf" $new_ca_name/etc
      cp -a $template_dir/etc/"identity.conf" $new_ca_name/etc/smime.conf
      cp -a $template_dir/etc/"identity.conf" $new_ca_name/etc/smime_multi.conf
#Hier werden die Voraussetzungen geschaffen, dass man auch auf einfache Weise S/MIME-Zertifikate erstellen kann
#sogar für mehrere EMail-Adressen gleichzeitig
#(mit dieser DI kann man dann EMails sowohl verschlüsseln als auch signieren!)
	  sed -i -- "s/identity/smime/g"  $new_ca_name/etc/smime.conf
	  sed -i -- "s/Identity/S\/MIME/g"  $new_ca_name/etc/smime.conf
	  sed -i -E -- "s/keyUsage(.*)/keyUsage\1,keyEncipherment/g"  $new_ca_name/etc/smime.conf
	  echo "" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "[ smime_ext ]" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "keyUsage                = critical,keyEncipherment,digitalSignature" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "basicConstraints        = CA:false" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "extendedKeyUsage        = emailProtection,msEFS,clientAuth,msSmartcardLogin" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "subjectKeyIdentifier    = hash" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "authorityKeyIdentifier  = keyid:always" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "authorityInfoAccess     = @issuer_info" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "crlDistributionPoints   = @crl_info" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "crlDistributionPoints   = @crl_info" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
		echo "certificatePolicies     = blueMediumAssurance" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
	  sed -i -- "s/identity/smime_multi/g"  $new_ca_name/etc/smime_multi.conf
	  sed -i -- "s/Identity/S\/MIME-Multi/g"  $new_ca_name/etc/smime_multi.conf
	  sed -i -E -- "s/keyUsage(.*)/keyUsage\1,keyEncipherment/g"  $new_ca_name/etc/smime_multi.conf
	  sed -i -E -- "s/subjectAltName( *= *.*)/subjectAltName\1,\$ENV::SAN/g"  $new_ca_name/etc/smime_multi.conf
      awk '/\[ identity_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance/, "#certificatePolicies = identityCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ encryption_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance/, "#certificatePolicies = encryptionCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      awk '/\[ smime_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance/, "#certificatePolicies = smimeCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      ;;
    software)
      cp -a templates/codesign.conf "$new_ca_name/etc"
      awk '/\[ codesign_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance,blueMediumDevice/, "#certificatePolicies = codesignCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
      rm $new_ca_name/etc/$new_ca_name"-ca.conf"
      mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"
      ;;
  esac
#falls root CA...
awk '/\[ intermediate_ca_ext \]/ || f == 1 && sub(/certificatePolicies     = blueMediumAssurance,blueMediumDevice/, "#certificatePolicies = intermediateCPS") { ++f } 1' $new_ca_name/etc/$new_ca_name"-ca.conf" >$new_ca_name/etc/$new_ca_name"-ca.intermediate"
rm $new_ca_name/etc/$new_ca_name"-ca.conf"
mv $new_ca_name/etc/$new_ca_name"-ca.intermediate" $new_ca_name/etc/$new_ca_name"-ca.conf"

#Anschließend wird in den kopierten Dateien der Name der CA durch den vom Nutzer gewählten ersetzt
#$dialog_exe --backtitle "Info" --msgbox "s/${ca_type}-ca/${new_ca_name}-ca/g\n$new_ca_name/etc/$ca_type"-ca.conf"" 9 52

sed -i -- "s/${ca_type}-ca /${new_ca_name}-ca /g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/${ca_type}_ca /${new_ca_name}_ca /g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/ca.cer/ca.crt/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"

#An den Policies wird ein wenig herumgefeilt
sed -i -E -- "s/(countryName *= *)match(.*)/\1supplied\2/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/match_pol/match_O_pol/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -E -- "s/(commonName *= *)optional(.*)/\1supplied\2/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/any_pol/minimal_pol/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"

if [ -e ca_presets.ini ]; then
. ./ca_presets.ini
fi

condition=1
while [ $condition -eq 1 ]
do
condition=0
$dialog_exe --backtitle "CA configuration" \
	    --form " Please give some information - use [up] [down] to select input field " 0 0 0 \
	    "countryName" 2 4 "${countryName:-DE}" 2 25 40 0\
	    "organizationName" 4 4 "${organizationName:-}" 4 25 40 0\
	    "organizationalUnitName" 6 4 "${organizationalUnitName:-}" 6 25 40 0\
	    "commonName" 8 4 "${commonName:-}" 8 25 40 0\
	    "base_url" 10 4 "${base_url:-http://}" 10 25 40 0\
	    2>$_temp

	if [ ${?} -ne 0 ]; then exit 127; fi
    result=`cat $_temp`
    echo "Result=$result"
#    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
countryName=`cat $_temp |cut -d"
" -f 1`
organizationName=`cat $_temp |cut -d"
" -f 2`
organizationalUnitName=`cat $_temp |cut -d"
" -f 3`
commonName=`cat $_temp |cut -d"
" -f 4`
base_url=`cat $_temp |cut -d"
" -f 5`
if [ "$countryName" = "" ] || [ "$organizationName" = "" ] || [ "$organizationalUnitName" = "" ] || [ "$commonName" = "" ] || [ "$base_url" = "" ]; then
echo "You must fill out all the fields!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
done

arg=`echo -n "s/organizationalUnitName  = \".*?\"/organizationalUnitName  = \"${organizationalUnitName}\"/g"`
#$dialog_exe --backtitle "Info" --msgbox "$arg" 9 52
sed -i -E -- "s/# ([^ ]*) ([^ ]*) CA.*/# ${commonName} . ${organizationName} . ${organizationalUnitName}  \2 CA/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s|base_url *= .*|base_url = ${base_url}|g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/countryName *= \".*\"/countryName = \"${countryName}\"/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/organizationName *= \".*\"/organizationName = \"${organizationName}\"/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/organizationalUnitName *= \".*\"/organizationalUnitName  = \"${organizationalUnitName}\"/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- "s/commonName *= \".*\"/commonName  = \"${commonName}\"/g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -E -- 's/^certificatePolicies/#certificatePolicies/g' $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- 's_$dir/ca/$ca_$dir/ca_g' $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -- 's_$dir/ca.crt_$dir/ca/$ca.crt_g' $new_ca_name/etc/$new_ca_name"-ca.conf"
sed -i -E -- 's#(new_certs_dir.*)dir/ca#\1dir/certs#g' $new_ca_name/etc/$new_ca_name"-ca.conf"

if [ -z ${key_length+x} ]; then
#Die Schlüssellänge und der zu benutzende Hash-Algorithmus werden festgelegt
$dialog_exe --backtitle "Available key lengths" \
           --title "Select one" --radiolist \
			"Choose one of the available key lengths" 16 40 8 \
			1 1024 off\
			2 2048 off\
			3 4096 on\
			2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		case $sel in 
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
fi

if [ -z ${hash_alg+x} ]; then
$dialog_exe --backtitle "Available hash algorithms" \
           --title "Select one" --radiolist \
			"Choose one of the available hash algorithms" 16 40 8\
			1 MD5 off\
			2 SHA-1 off\
			3 SHA-224 off\
			4 SHA-256 on\
			5 SHA-348 off\
			6 SHA-512 off\
			2> $_temp
    if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		case $sel in 
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
fi
sed -i -E -- "s/(default_md *= *)sha1(.*)/\1$hash_alg\2/g"  $new_ca_name/etc/*.conf
sed -i -E -- "s/(default_bits *= *)2048(.*)/\1$key_length\2/g"  $new_ca_name/etc/*.conf


#Die Konfiguration der CA wird festgelegt: Welche Angaben müssen in einem Request enthalten sein und 
#Welche der Angaben  müssen bestimmten Vorgaben genügen.

#Welche Defaults sollen das Erstellen eines CSR erleichtern?
conf_files=$(find $new_ca_name/etc/ -maxdepth 1 ! -name '*ca.conf' ! -name '.'|rev|cut -d / -f 1|rev)
menuitems=""
emptySpace=""
for item in ${conf_files}
    do
            menuitems="$menuitems ${item} '' off " # subst. Blanks with "_"

done
if [ "$menuitems" = "" ];then
echo "no issuing cas need to be configured - skipping this part"
else
$dialog_exe --backtitle "Default Values for CSRs (scroll with PgUp, PgDown)" --msgbox "The next form shows a list with the different flavors of certificates this new CA is able to issue. You are prompted \
to select all of those flavors you want to specify default values for. These default values are stored inside the generated
client configurations an end user can use to create certificate signing requests. With this you can make the life
of your end users easier. If for example you create a CA for identity management, the end users must provide details such as country,
locality, organization and so on. If the CA is meant to manage digital identities for the employees of a company, chances are
that each and every one of them will enter the same for organization - why not save them the hassle and fill it out beforehand? This
is what these default values are for." 0 0
$dialog_exe --backtitle "Available CA configurations" \
           --title "Select some" --checklist \
           "Choose the available certificate types you want to specify defaults for" 16 40 8 $menuitems 2> $_temp
if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		echo $sel
	else
		exit 255
    fi
#countryName=""
#stateOrProvinceName=""
#localityName=""
#organizationName=""
#organizationalUnitName=""
commonName=""
emailAddress=""
for item in ${sel}
    do
$dialog_exe --backtitle "CSR defaults for $item" \
	    --form " Specify defaults for $item - use [up] [down] to select input field " 0 0 0 \
	    "countryName" 2 4 "${countryName:-DE}" 2 25 40 0\
	    "stateOrProvinceName" 4 4 "${stateOrProvinceName:-}" 4 25 40 0\
	    "localityName" 6 4 "${localityName:-}" 6 25 40 0\
	    "organizationName" 8 4 "${organizationName:-}" 8 25 40 0\
	    "organizationalUnitName" 10 4 "${organizationalUnitName:-}" 10 25 40 0\
	    "commonName" 12 4 "${commonName:-}" 12 25 40 64\
	    "emailAddress" 14 4 "${emailAddress:-}" 14 25 40 80\
	    2>$_temp
	
	if [ ${?} -ne 0 ]; then exit 127; fi   
    result=`cat $_temp`
    echo "Result=$result"
#    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
countryName=`cat $_temp |cut -d"
" -f 1`
stateOrProvinceName=`cat $_temp |cut -d"
" -f 2`
localityName=`cat $_temp |cut -d"
" -f 3`
organizationName=`cat $_temp |cut -d"
" -f 4`
organizationalUnitName=`cat $_temp |cut -d"
" -f 5`
commonName=`cat $_temp |cut -d"
" -f 6`
emailAddress=`cat $_temp |cut -d"
" -f 7`
if [ ! "$countryName" = "" ]; then
sed -i -E -- "/countryName *=.*/a countryName_default = \"${countryName}\""  $new_ca_name/etc/$item
fi
if [ ! "$stateOrProvinceName" = "" ]; then
sed -i -E -- "/stateOrProvinceName *=.*/a stateOrProvinceName_default = \"${stateOrProvinceName}\""  $new_ca_name/etc/$item
fi
if [ ! "$localityName" = "" ]; then
sed -i -E -- "/localityName *=.*/a localityName_default = \"${localityName}\""  $new_ca_name/etc/$item
fi
if [ ! "$organizationName" = "" ]; then
sed -i -E -- "/organizationName *=.*/a organizationName_default = \"${organizationName}\""  $new_ca_name/etc/$item
fi
if [ ! "$organizationalUnitName" = "" ]; then
sed -i -E -- "/organizationalUnitName *=.*/a organizationalUnitName_default = \"${organizationalUnitName}\""  $new_ca_name/etc/$item
fi
if [ ! "$commonName" = "" ]; then
sed -i -E -- "/commonName *=.*/a commonName_default = \"${commonName}\""  $new_ca_name/etc/$item
fi
if [ ! "$emailAddress" = "" ]; then
sed -i -E -- "/emailAddress *=.*/a emailAddress_default = \"${emailAddress}\""  $new_ca_name/etc/$item
fi
done
fi

if ! grep "countryName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/countryName *=.*/a #countryName_default = \"default countryName\""  $new_ca_name/etc/$item
fi
if ! grep "stateOrProvinceName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/stateOrProvinceName *=.*/a #stateOrProvinceName_default = \"default stateOrProvinceName\""  $new_ca_name/etc/$item
fi
if ! grep "localityName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/localityName *=.*/a #localityName_default = \"default localityName\""  $new_ca_name/etc/$item
fi
if ! grep "organizationName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/organizationName *=.*/a #organizationName_default = \"default organizationName\""  $new_ca_name/etc/$item
fi
if ! grep "organizationalUnitName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/organizationalUnitName *=.*/a #organizationalUnitName_default = \"default organizationalUnitName\""  $new_ca_name/etc/$item
fi
if ! grep "commonName_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/commonName *=.*/a #commonName_default = \"default commonName\""  $new_ca_name/etc/$item
fi
if ! grep "emailAddress_default" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/emailAddress *=.*/a #emailAddress_default = \"default emailAddress\""  $new_ca_name/etc/$item
fi

if ! grep "countryName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/countryName *=.*/a #countryName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*countryName_max *=.*/i #countryName_min = 1"  $new_ca_name/etc/$item
if ! grep "stateOrProvinceName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/stateOrProvinceName *=.*/a #stateOrProvinceName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*stateOrProvinceName_max *=.*/i #stateOrProvinceName_min = 1"  $new_ca_name/etc/$item
if ! grep "localityName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/localityName *=.*/a #localityName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*localityName_max *=.*/i #localityName_min = 1"  $new_ca_name/etc/$item
if ! grep "organizationName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/organizationName *=.*/a #organizationName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*organizationName_max *=.*/i #organizationName_min = 1"  $new_ca_name/etc/$item
if ! grep "organizationalUnitName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/organizationalUnitName *=.*/a #organizationalUnitName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*organizationalUnitName_max *=.*/i #organizationalUnitName_min = 1"  $new_ca_name/etc/$item
if ! grep "commonName_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/commonName *=.*/a #commonName_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*commonName_max *=.*/i #commonName_min = 1"  $new_ca_name/etc/$item
if ! grep "emailAddress_max" "$new_ca_name/etc/$item" ; then
  sed -i -E -- "/emailAddress *=.*/a #emailAddress_max = 255"  $new_ca_name/etc/$item
fi
sed -i -E -- "/.*emailAddress_max *=.*/i #emailAddress_min\t= 1"  $new_ca_name/etc/$item


if [ -z ${no_cpss+x} ]; then
#Custom Policies
conf_files=`find $new_ca_name/etc/ -maxdepth 1 ! -name ''"$new_ca_name"'-ca.conf' ! -name '.'|rev|cut -d / -f 1|rev`
menuitems=""
emptySpace=""
for item in ${conf_files}
    do
            menuitems="$menuitems ${item} '' off " # subst. Blanks with "_"
done
#if policies for root cas would be allowed...
if [ "$menuitems" = "" ];then
    if [ "$ca_type" = "root" ];then
      menuitems="$menuitems intermediate '' off "
    fi
fi
if [ "$menuitems" = "" ];then
echo "no issuing cas need to be configured - skipping this part"
else
$dialog_exe --backtitle "Certificate Policy Statements (scroll with PgUp, PgDown)" --msgbox "The next form shows a list with the different flavors of certificates this new CA is able to issue. You are prompted \
to select all of those flavors you want to specify Certificate Policy Statements (CPSs) for. Remember: for a Certificate Authority Hierarchy to \
be valid according to RFC 5280, all Certificate Authorities below one that does supply CPSs have to do this too! For each of those selected, you have to specify the policies afterwards: \
Either by only giving OID and URI or by giving OID and URI and an additional User notice - Text or by filling out all form fields. \
Important: If either Org or Notice numbers is given, the other field must be given too, else, the policy is not added to the \
configuration!" 0 0
$dialog_exe --backtitle "Available CA configurations" \
           --title "Select some" --checklist \
           "Choose the available certificate types you want to specify CPSs for" 16 40 8 $menuitems 2> $_temp
if [ $? -eq 0 ]; then
         sel=`cat $_temp`
		echo $sel
	else
		exit 255
    fi
        cpsoid=""
        cpsuri="${base_url:-}"
        cpsexplicit=""
        cpsorg=""
        cpsnumbers=""
for item in ${sel}
    do
        caconfig=`echo -n "$item"|cut -d "." -f 1`
		caconfig=`echo -n "$caconfig"|cut -d "-" -f 1`
        $dialog_exe --backtitle "CPS information" \
                --form " Specify information for ${caconfig} - use [up] [down] to select input field " 0 0 0 \
                "OID" 2 4 "${cpsoid}" 2 25 40 0\
                "CPS URI" 4 4 "${cpsuri}" 4 25 40 0\
                "User notice - Text" 6 4 "${cpsexplicit}" 6 25 40 0\
                "User notice - Org" 8 4 "${cpsorg}" 8 25 40 0\
                "User notice - Notice numbers" 10 4 "${cpsnumbers}" 10 25 40 0\
                2>$_temp

            if [ ${?} -ne 0 ]; then exit 127; fi
            result=`cat $_temp`
            echo "Result=$result"
        #    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
cpsoid=`cat $_temp |cut -d"
" -f 1`
cpsuri=`cat $_temp |cut -d"
" -f 2`
cpsexplicit=`cat $_temp |cut -d"
" -f 3`
cpsorg=`cat $_temp |cut -d"
" -f 4`
cpsnumbers=`cat $_temp |cut -d"
" -f 5`
        if [ ! "$cpsoid" = "" ]; then
          cpsfragment="certificatePolicies = @${caconfig}CPS\n\n\
[ ${caconfig}CPS ]\n\
policyIdentifier=${cpsoid}\n"
          if [ ! "$cpsuri" = "" ]; then
            cpsfragment="${cpsfragment}CPS=\"${cpsuri}\"\n"
            if [ ! "$cpsexplicit" = "" ]; then
              cpsfragment="${cpsfragment}userNotice=@${caconfig}CPSNotice\n\n\
[ ${caconfig}CPSNotice ]\n\
explicitText=\"${cpsexplicit}\"\n"
              if [ ! "$cpsorg" = "" ] && [ ! "$cpsnumbers" = "" ]; then
                cpsfragment="${cpsfragment}notice=@${caconfig}CPSNoticeref\n\n\
[ ${caconfig}CPSNoticeref ]\n\
organisation=\"${cpsorg}\"\n\
noticeNumbers=${cpsnumbers}\n"
              fi
            fi
#            $dialog_exe --title "sed cmd line" --cr-wrap --msgbox "sed -i -- \"s|#certificatePolicies = ${caconfig}CPS|${cpsfragment}|g\"  $new_ca_name/etc/$new_ca_name\"-ca.conf\"" 12 52
            sed -i -- "s|#certificatePolicies = ${caconfig}CPS|${cpsfragment}|g"  $new_ca_name/etc/$new_ca_name"-ca.conf"
          fi
        fi
done
fi
fi
#Custom OIDs
echo "" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
echo "[ additional_oids ]" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
if [ -z ${no_custom_oids+x} ]; then
$dialog_exe --backtitle "Custom OIDs (scroll with PgUp, PgDown)" --msgbox "It is possible to give text descriptions for any proprietary OIDs you want to use in your issued certificates.\
The next form gives you the opportunity to specify them and their associated description together with an identifier (must not contain spaces) one by one. Once you entered
all your OIDs and their descriptions - just leave at least one field of the form blank and the script will automatically proceed to the next step" 0 0
condition=1
Identifier="CustomOid1"
OID=""
Description=""
while [ $condition -eq 1 ]
do
condition=1
$dialog_exe --backtitle "Custom OID descriptions" \
	    --form " Please give your OID and their description - use [up] [down] to select input field " 0 0 0 \
	    "Identifier" 2 4 "${Identifier}" 2 25 40 0\
	    "OID" 4 4 "${OID}" 4 25 40 0\
	    "Description" 6 4 "${Description}" 6 25 40 255\
	    2>$_temp

	if [ ${?} -ne 0 ]; then exit 127; fi
    result=`cat $_temp`
    echo "Result=$result"
#    $dialog_exe --title "Items are separated by \\n" --cr-wrap --msgbox "\nYou entered:\n$result" 12 52
Identifier=`cat $_temp |cut -d"
" -f 1`
OID=`cat $_temp |cut -d"
" -f 2`
Description=`cat $_temp |cut -d"
" -f 3`
if [ "$OID" = "" ] || [ "$Description" = "" ] || [ "$Identifier" = "" ]; then
condition=0
else
echo "${Identifier} = ${Description}, ${OID}" >>$new_ca_name/etc/$new_ca_name"-ca.conf"
fi
done
fi

#Key management
if [ "$preexisting_key_file" = "" ]; then
. ./ask_for_passwd.sh
else
while [ $condition -eq 1 ]
do
result=$($dialog_exe --stdout --backtitle "Password for private key" \
	    --form " Please specify - use [up] [down] to select input field " 0 0 0 \
	    "Password (max 254 chars)" 2 4 "" 2 25 40 255)
	
	if [ ${?} -ne 0 ]; then exit 127; fi   
#    result=`cat $_temp`
    echo "Result=$result"
Password=`echo "$result"|cut -d"
" -f 1`
if [ "$Password" = "" ]; then
echo "You must give a password!"
$dialog_exe --backtitle "Error" --msgbox "You must give a password!" 9 52
condition=1
fi
done
fi
# output der Daten in eine tsv-Datei

log_file_name=$($dialog_exe --stdout --backtitle "Log" --fselect ./${new_ca_name}_log.tsv 0 0)
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
#  $dialog_exe --backtitle "Info" --msgbox "trying to build key and csr for ${new_ca_name} using $Password" 9 52
  expect ca_csr.xpct ${new_ca_name} $Password
  if [ ! -e "${new_ca_name}/ca/private/${new_ca_name}-ca.key" ]; then
    $dialog_exe --backtitle "Error" --msgbox "key ${new_ca_name}/ca/private/${new_ca_name}-ca.key could not be created!" 9 52
    exit 224
  fi
else
cp $preexisting_key_file ${new_ca_name}/ca/private/${new_ca_name}-ca.key
expect ca_csr_with_key.xpct ${new_ca_name} $Password $preexisting_key_file
fi
#Der Anwender wird per $dialog_exe darüber informiert, dass er dem Zertifikatsrequest bei der CA, von der die Konfiguration stammte,
#einreichen kann.
openssl req -text -in ${new_ca_name}/ca/${new_ca_name}-ca.csr -out /tmp/csr.pem

$dialog_exe --backtitle "Certificate Request" --textbox /tmp/csr.pem 0 0

$(expect priv_key_fingerprint.xpct "${new_ca_name}/ca/private/${new_ca_name}-ca.key" md5 ${Password})
mac_md5=$(cat /tmp/md5)
$(expect priv_key_fingerprint.xpct "${new_ca_name}/ca/private/${new_ca_name}-ca.key" sha1 ${Password})
mac_sha1=$(cat /tmp/sha1)
$(expect priv_key_fingerprint.xpct "${new_ca_name}/ca/private/${new_ca_name}-ca.key" sha256 ${Password})
mac_sha256=$(cat /tmp/sha256)
$(expect priv_key_fingerprint.xpct "${new_ca_name}/ca/private/${new_ca_name}-ca.key" sha512 ${Password})
mac_sha512=$(cat /tmp/sha512)

$dialog_exe --backtitle "Info (scroll with PgUp, PgDown)" --msgbox "The key is in ${new_ca_name}/ca/private/${new_ca_name}-ca.key\n\nMD5-Fingerprint: ${mac_md5}\nSHA1-Fingerprint: ${mac_sha1}\nSHA256-Fingerprint: ${mac_sha256}\nSHA512-Fingerprint: ${mac_sha512}\n\nThe Cert Req is in ${new_ca_name}/ca/${new_ca_name}-ca.csr\n\nYou can now ask your CA to sign the request!\n\nThe configurations needed by clients to generate certificate signing requests are in ${new_ca_name}/ca/etc. Available are: $conf_files" 0 0

$dialog_exe --backtitle "Custom Policies (scroll with PgUp, PgDown)" --msgbox "At this time, two policies are defined in the CA configuration file $new_ca_name/etc/$new_ca_name-ca.conf. If you want to add more or add some of your own - feel free to add them using the one named minimal_pol as a template. You are free when naming them but if the names do not end with _pol, the script for signing CSRs will not pick them up so you will not be able to use them when actually signing CSRs!" 0 0

#ca=${new_ca_name}
cpsresources=`grep -e "^CPS\s*=.*$" ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2| sed s/\"//g`
#addresources=`grep \$base_url ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2|rev|cut -d "#" -f 2|rev|sed -E "s/^\s*//g"|sed -E "s/ca.(cer|crl)/${new_ca_name}.\1/g"`
base_url=`grep -e "^base_url\s*=\s*.*$" ${new_ca_name}/etc/${new_ca_name}"-ca.conf"|cut -d "=" -f 2| sed -E "s/^\s*//g"`
#$dialog_exe --title "resources" --cr-wrap --msgbox "$ca \n $base_url \n ${new_ca_name}\n ${addresources}" 12 52
resources="${base_url}/${new_ca_name}.crt\n${base_url}/${new_ca_name}.crl\n${cpsresources}"

$dialog_exe --backtitle "Resources to provide (scroll with PgUp, PgDown)" --msgbox "You must provide the following resources after receiving and installing \
your certificate to make your shiny new CA fully functional:\n$resources" 0 0

#log schreiben

if [ "$log_file_name" != "" ]; then
echo "name\tCN\tprivate key pass\tMD5\tSHA1\tSHA256\tSHA512" > ${log_file_name}
echo "${new_ca_name}\t${organizationalUnitName}\t****\t${mac_md5}\t${mac_sha1}\t${mac_sha256}\t${mac_sha512}" >> ${log_file_name}
chmod 600 ${log_file_name}
$dialog_exe --backtitle "Info (scroll with PgUp, PgDown)" --msgbox "log file written to ${log_file_name}" 0 0
fi
Password=""
#am Ende wird gecheckt, ob die Variable offline_template_dir gesetzt war
#falls nicht, wird versucht, die ausgecheckte expert-pki  
#wieder zu löschen
if [ "$offline_template_dir" = "" ]
then
	rm -rf __template__
fi
clear

