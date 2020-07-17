#!/bin/bash

#ldaphost=<ldap_IP>
#basedn=<帳號>
#basednpw="密碼"
#bindDN="ou=example,dc=example,dc=com"  ## 搜尋的位置
# 如果修改下方三條件, 會連同 rancher的 project 一起刪除
#rancherurl=<位置>
#BearerToken=<>
#clusterid=<>

## 確定LDAP 連線正常
ldapstatus=$(ldapsearch -x -h $ldaphost -D $basedn -p 389 -w $basednpw |grep numResponses)

## 擷取profile 的email欄位
email=$(kubectl get profile -o json | jq '.items' |jq .[].spec.owner.name | awk -F'"' '{print $2}')
arrayemail=( $email )

## 擷取dex lcoal 設定的email欄位
dexlocalaccount=$(kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}'|grep email |awk -F': ' '{print $2}')


## rancher 將 { name:<projectname>, id:<projectid> }
arr=$(curl -k -u $BearerToken -X GET  https://$rancherurl/v3/clusters/$clusterid/projects |jq .data| jq .[] |jq '{ name : .name , id : .id}')



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
          ## 將 name為 foo的 projectname 找到他的 rancher projectid
          if [ ! -z "$rancherurl" ] && [ ! -z "$BearerToken" ]
		  then
              pname=$name
              projectid=$(echo $arr |jq '. | select(.name=="'$pname'") | .id' | awk -F'"' '{print $2}')
              ## 刪除rancher project
              curl -k -u $BearerToken -X DELETE -H 'Accept: application/json' https://$rancherurl/v3/clusters/c-djc8z/projects/$projectid
          fi
    else
          echo "Ldap/dex_local have user nothing"
    fi
done



## 以下補充
## rancher 新增project
# curl -k -u "token-mq62m:566rhbhmbgrbd6q6d" -X POST -H 'Content-Type: application/json' -d '{"name": "foo"}' 'https://rancher.10.1.190.80.nip.io/v3/clusters/c-djc8z/projects' 
 
 
## rancher官方提供 刪除projectid
# curl -k -u "token-mq62m:566rcljjjhbhmbgrbd6q6d" -X DELETE -H 'Accept: application/json' 'https://rancher.10.1.190.80.nip.io/v3/clusters/c-djc8z/projects/c-djc8z:p-mh8pm' 
