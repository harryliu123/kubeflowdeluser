#!/bin/bash

#ldaphost=<ldap_IP>
#basedn=<帳號>
#basednpw="密碼"
#bindDN="ou=example,dc=example,dc=com"  ## 搜尋的位置

ldapstatus=$(ldapsearch -x -h $ldaphost -D $basedn -p 389 -w $basednpw |grep numResponses)
name=$(kubectl get profile -o json | jq '.items' |jq .[].spec.owner.name |grep -v admin| awk -F'"' '{print $2}'| awk -F'@' '{print $1}')
array=( $name )
for i in "${array[@]}"
do
    status=$(ldapsearch \
        -x -h $ldaphost \
        -D $basedn \
        -p 389 \
        -w $basednpw \
        -b "$bindDN" "cn=$i" \
        -s sub "(cn=*)" cn | grep numEntries)
    echo $i
    if [ -z "$status" ] && [ ! -z "$ldapstatus" ]
    then
          echo "delete user $i"
          kubectl delete profile $i
    else
          echo "Ldap have user nothing"
    fi
done