#!/bin/bash

echo $(date +"%Y-%m-%d %H:%M:%S") > scan_timestamp
cat scan_timestamp | cut -d' ' -f1 > scan_date

file="rangos_orange.txt"
while IFS= read -r line
do
        output=$(echo $line | sed 's/\//-/')
        sudo masscan --rate 1000.00 -p10000,10011 $line -oD targets/$output.txt
        cat targets/$output.txt  | jq -jr '. | "http://\(.ip):\(.port)\n"' > targets/$output.ips
        rm targets/$output.txt
        ./get_info.sh targets/$output.ips &

done <"$file"



