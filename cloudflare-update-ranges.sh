#!/bin/bash
#/opt/scripts/cloudflare-update-ip-ranges.sh

# Location of the nginx config file that contains the CloudFlare IP addresses.
CF_NGINX_CONFIG_FILE="/etc/nginx/cloudflare"
LOG_FILE="/var/log/cloudflare-nginx"

# The URLs with the actual IP addresses used by CloudFlare.
CF_URL_IP4="https://www.cloudflare.com/ips-v4/"
CF_URL_IP6="https://www.cloudflare.com/ips-v6/"

# Temporary files.
CF_TEMP_IP4="/tmp/cloudflare-ips-v4.txt"
CF_TEMP_IP6="/tmp/cloudflare-ips-v6.txt"

# Check if there has been a change - if not, exit
if [ -f $CF_TEMP_IP4 ] && [ -f $CF_TEMP_IP6 ]
then
last_ip4checksum=$(cat $CF_TEMP_IP4 | md5sum)
last_ip6checksum=$(cat $CF_TEMP_IP6 | md5sum)
ip4checksum=$(curl --silent $CF_URL_IP4 | md5sum)
ip6checksum=$(curl --silent $CF_URL_IP6 | md5sum)

if [ "$last_ip4checksum" = "$ip4checksum" ] && [ "$last_ip6checksum" = "$ip6checksum" ]
then
exit 1
fi
fi

# Download the files.
if [ -f /usr/bin/curl ];
then
curl --silent --output $CF_TEMP_IP4 $CF_URL_IP4
curl --silent --output $CF_TEMP_IP6 $CF_URL_IP6
elif [ -f /usr/bin/wget ];
then
wget --quiet --output-document=$CF_TEMP_IP4 --no-check-certificate $CF_URL_IP4
wget --quiet --output-document=$CF_TEMP_IP6 --no-check-certificate $CF_URL_IP6
else
echo "$(date) $0: Unable to download CloudFlare files." >> $LOG_FILE
exit 1
fi

# Generate the new config file.
NGINX_CONFIG_CONTENT="# CloudFlare IP Ranges\n"
NGINX_CONFIG_CONTENT+="# Generated at $(date) by $0\n"
NGINX_CONFIG_CONTENT+="\n"

NGINX_CONFIG_CONTENT+="# - IPv4 ($CF_URL_IP4)\n"
NGINX_CONFIG_CONTENT+=$(awk '{ print "set_real_ip_from " $0 ";\\n" }' $CF_TEMP_IP4)
NGINX_CONFIG_CONTENT+="\n"

NGINX_CONFIG_CONTENT+="# - IPv6 ($CF_URL_IP6)\n"
NGINX_CONFIG_CONTENT+=$(awk '{ print "set_real_ip_from " $0 ";\\n" }' $CF_TEMP_IP6)
NGINX_CONFIG_CONTENT+="\n"

NGINX_CONFIG_CONTENT+="real_ip_header CF-Connecting-IP;\n"
NGINX_CONFIG_CONTENT+="\n"

echo -e $NGINX_CONFIG_CONTENT > $CF_NGINX_CONFIG_FILE

# Test nginx config
( $(sudo /usr/sbin/nginx -t) ) > /dev/null 2>&1
if [ $? ]
then
echo "$(date) $0: CloudFlare IP's have been updated @ $CF_NGINX_CONFIG_FILE" >> $LOG_FILE
# Reload the nginx config.
( $(service nginx reload) ) > /dev/null 2>&1
else
echo "$(date) $0: The configuration file $CF_NGINX_CONFIG_FILE (OR /etc/nginx/nginx.conf) syntax is NOT valid, please check. NO restart of nginx." >> $LOG_FILE
fi
