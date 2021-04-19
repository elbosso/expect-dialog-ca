#!/bin/bash
# shellcheck disable=SC2154,SC2181
function get_private_key_file {
  local ca_dir_name=$1
  local _privkey_file_name=$2
  local dialog_exe=$3
  #der private Schlüssel wird ausgewählt
  condition=1;
  while [ $condition -eq 1 ]
  do
  condition=0
  if [ "$_privkey_file_name" == "" ]; then
    _privkey_file_name=$($dialog_exe --stdout --backtitle "CAs Private Key" --fselect "$ca_dir_name/ca/private/" 0 90)
    if [ ${?} -ne 0 ]; then exit 127; fi
  fi
    if [ "$_privkey_file_name" = "" ]; then
    echo "A private key must be given!"
    $dialog_exe --backtitle "Error" --msgbox "A private key must be given!" 9 52
    condition=1;
    _privkey_file_name=""
    elif [ ! -f "$_privkey_file_name" ]; then
    echo "A private key must be a file!"
    $dialog_exe --backtitle "Error" --msgbox "A private key must be a file!" 9 52
    condition=1;
    _privkey_file_name=""
    fi
  done
  privkey_file_name=$_privkey_file_name
}
