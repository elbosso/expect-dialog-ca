#!/bin/bash
# shellcheck disable=SC2154,SC2181
proposed_pass=""
if [ -x "$(command -v makepasswd)" ]; then
  proposed_pass=$(makepasswd -count 1 -minchars 8)
fi
condition=1
while [ $condition -eq 1 ]
do
condition=0
result=$($dialog_exe --stdout --backtitle "Password for private key ${purpose}" \
	    --form " Please specify - use [up] [down] to select input field " 0 0 0 \
	    "Password (max 254 chars)" 2 4 "$proposed_pass" 2 25 40 255\
	    "Verification (max 254 chars)" 4 4 "" 4 25 40 255)

	if [ ${?} -ne 0 ]; then exit 127; fi   
#    result=`cat $_temp`
    echo "Result=$result"

Password=$(echo "$result"|cut -d"
" -f 1)
Verification=$(echo "$result" |cut -d"
" -f 2)
#$dialog_exe --backtitle "Info" --msgbox "$result\n--\n$Password\n$Verification" 9 52
if [ "$Password" = "" ] || [ "$Verification" = "" ]; then
echo "You must fill out all the fields!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields!" 9 52
condition=1
fi
if [ "$Verification" != "$Password" ] && [ $condition -eq 0 ]; then
echo "Password and verification differ!"
$dialog_exe --backtitle "Error" --msgbox "You must fill out all the fields identically!" 9 52
condition=1
fi
if [ ${#Password} -lt 4 ] && [ $condition -eq 0 ]; then
$dialog_exe --backtitle "Error" --msgbox "A password must be at least 4 characters long!" 9 52
condition=1
fi
done
proposed_pass=""
