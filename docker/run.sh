#!/bin/bash

#ldaphost=<ldap_IP>
#basedn=<帳號>
#basednpw="密碼"
#bindDN="ou=example,dc=example,dc=com"  ## 搜尋的位置

## 確定LDAP 連線正常
ldapstatus=$(ldapsearch -x -h $ldaphost -D $basedn -p 389 -w $basednpw |grep numResponses)

## 擷取profile 的email欄位
email=$(kubectl get profile -o json | jq '.items' |jq .[].spec.owner.name | awk -F'"' '{print $2}')
arrayemail=( $email )

## 擷取dex lcoal 設定的email欄位
dexlocalaccount=$(kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}'|grep email |awk -F': ' '{print $2}')

## 比對 profile email 是否存在於 dex lcoal 設定的email欄位 && profile name 是否存在於 ldap 的帳號
## 比對不到代表 ldap 已經刪除的帳號, 進行profile 刪除
for i in "${arrayemail[@]}"
do
    name=$(echo $i| awk -F'@' '{print $1}')
    echo $name
    dexlcoalstatus=$(echo $dexlocalaccount |grep $name)
    ldapnamestatus=$(ldapsearch \
        -x -h $ldaphost \
        -D $basedn \
        -p 389 \
        -w $basednpw \
        -b "$bindDN" "cn=$name" \
        -s sub "(cn=*)" cn | grep numEntries)

    if [ -z "$ldapnamestatus" ] && [ ! -z "$ldapstatus" ] && [ -z "$dexlcoalstatus" ]
    then
          echo "delete user $name"
          kubectl delete profile $name
    else
          echo "Ldap/dex_local have user nothing"
    fi
done