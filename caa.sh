#!/bin/bash
if [ $# -lt 1 ];then
	echo "you must specify a name!"
	exit 1;
fi
domain=$1
#echo $domain

#DIG_OPTIONS="@127.0.0.1 -p 5364"
DIG_OPTIONS=""

counter=1

domainpart=$(echo -n "$domain" |cut -d '.' -f "$counter"-)

while [ "$domainpart" != "" ]
do
#	echo "$domainpart"
	numberOfCaaRecords=$(dig $DIG_OPTIONS "$domainpart" caa | grep "ANSWER SECTION:" -A 10000000|grep -v ";;"|grep CAA|tr -s ' '|cut -d " " -f 2,3|grep "issue"|wc -l)
	if [ "$numberOfCaaRecords" -gt 0 ]; then
	        whitelisted=()
	        whitelistedwild=()
		numberOfCaaRecordsIssue=$(dig $DIG_OPTIONS "$domainpart" caa | grep "ANSWER SECTION:" -A 10000000|grep -v ";;"|grep CAA|tr -s ' '|cut -d " " -f 2,3|grep "issue "|wc -l)		
                numberOfCaaRecordsIssueWild=$(dig $DIG_OPTIONS "$domainpart" caa | grep "ANSWER SECTION:" -A 10000000|grep -v ";;"|grep CAA|tr -s ' '|cut -d " " -f 2,3|grep "issuewild"|wc -l)
                if [ "$numberOfCaaRecordsIssue" -gt 0 ]; then
                      RrIssue=$(dig $DIG_OPTIONS "$domainpart" caa | grep "ANSWER SECTION:" -A 10000000|grep -v ";;"|grep CAA|tr -s ' '|cut -d " " -f 2,3|grep "issue "|cut -d ' ' -f 2| tr -d '"')            
                      while IFS= read -r line; do
                      	#echo "issue: $line"
                      	domainName=$(echo -n "$line"|cut -d ';' -f 1)
#                      	echo "domain name $domainName"
                      	if [[ "$domainName" =~ ^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][-_\.a-zA-Z0-9]{1,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,13}|[a-zA-Z0-9-]{2,30}\.[a-zA-Z]{2,3})$ ]]; then
#                      		echo "$domainName is really a domain name"
				                  whitelisted+=( "$domainName" )
                      	fi
                      done <<< "$RrIssue"
                fi
                if [ "$numberOfCaaRecordsIssueWild" -gt 0 ]; then
                  RrIssueWild=$(dig $DIG_OPTIONS "$domainpart" caa | grep "ANSWER SECTION:" -A 10000000|grep -v ";;"|grep CAA|tr -s ' '|cut -d " " -f 2,3|grep "issuewild"|cut -d ' ' -f 2| tr -d '"')
                       while IFS= read -r line; do
                       	#echo "issue wild: $line"
                        domainName=$(echo -n "$line"|cut -d ';' -f 1)
#                        echo "domain name $domainName"
                        if [[ "$domainName" =~ ^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][-_\.a-zA-Z0-9]{1,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,13}|[a-zA-Z0-9-]{2,30}\.[a-zA-Z]{2,3})$ ]]; then
#                                echo "$domainName is really a domain name"
                                whitelistedwild+=( "$domainName" )
                        fi
                       done <<< "$RrIssueWild"
                fi
    #if [[ "$domain" =~ ^\*\..*$ ]]; then
    if [[ "$domain" == \*.* ]]; then
      echo "$domain is a wildcard domain name!"
      if [ ${#whitelistedwild[@]} -gt 0 ]; then
        echo "only the following cas may issue wildcard certificates for $domain:"
        for t in "${whitelistedwild[@]}"; do
          echo "$t"
        done
      else
#                        	if [ ${#whitelisted[@]} -gt 0 ]; then
#                        	        echo "only the following cas may issue wildcard certificates for $domain:"
#                                	for t in ${whitelisted[@]}; do
#                                	        echo "$t"
#                                	done
#	                        else
        	                        echo "No one is allowed to issue wildcard certificates for $domain!"
#        	                fi
			fi
		else
			echo "$domain is not a wildcard domain!"	
                        if [ ${#whitelisted[@]} -gt 0 ]; then
                                echo "only the following cas may issue certificates for $domain:"
                                for t in "${whitelisted[@]}"; do
                                        echo "$t"
                                done
                        else
                        	echo "No one is allowed to issue certificates for $domain!"
                        fi
		fi
		break
	fi
	counter=$(( $counter + 1 ))
	domainpart=$(echo -n "$domain" |cut -d '.' -f "$counter"-)
done