#!/bin/sh

drop_lasso(){
    rm -f /tmp/*drop.txt /tmp/drop_lasso
    curl -so /tmp/drop.txt  http://www.spamhaus.org/drop/drop.txt
    curl -so /tmp/edrop.txt http://www.spamhaus.org/drop/edrop.txt

    for files in $(find /tmp/ -maxdepth 1 -name '*drop.txt')
     do
        gawk -i inplace -F\; '$1{print $1;!/\;/}' "${files}"
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
    rm -f /tmp/geo_blacklist
    mv /etc/PF/geo_blacklist /root/geo_blacklist."$(date '+%Y-%m-%d')"
    cat /tmp/drop_lasso /tmp/country_ips > /tmp/geo_blacklist
    sort -n /tmp/geo_blacklist | uniq > /etc/PF/geo_blacklist
}

drop_lasso
ipdeny_countries
blacklist
