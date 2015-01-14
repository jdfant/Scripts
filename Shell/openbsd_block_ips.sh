#!/bin/sh

drop_lasso(){
    rm -f /tmp/*drop.txt
    curl -so /tmp/drop.txt  http://www.spamhaus.org/drop/drop.txt
    curl -so /tmp/edrop.txt http://www.spamhaus.org/drop/edrop.txt

    for files in $(ls -d /tmp/*drop.txt)
     do
        gawk -i inplace -F\; '$1{print $1;!/\;/}' ${files}
    done

    awk '{if (!a[$0]++) print}' /tmp/*drop.txt|sort -n >> /tmp/drop_lasso
}

ipdeny_countries(){
    rm -f /tmp/country_*
    curl -sO \
        http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/in-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/kr-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/kp-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/ro-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone \
        http://www.ipdeny.com/ipblocks/data/aggregated/ua-aggregated.zone \
            >> /tmp/country_ips_unsorted
    sort -n /tmp/country_ips_unsorted > /tmp/country_ips
}

blacklist(){
    mv /etc/PF/blacklist /root/blacklist.$(date '+%b.%d.%Y')
    sort -n -m /tmp/drop_lasso /tmp/country_ips > /etc/PF/blacklist 
    sort -nc /tmp/blacklist.$(date '+%b.%d.%Y')

    if [ $? -eq 0 ];then
        exit 0
    else
        echo -e "\n !!! blacklist file is not sorted\n Look into it" >&2
        exit 1
    fi
}

drop_lasso
ipdeny_countries
blacklist
