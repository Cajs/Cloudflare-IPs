# Cloudflare-IPs

Users of Cloudflare will know that it acts as a reverse proxy. This has the unfortunate effect of affecting NGINX's ability to see the visitor IP's.

This script automatically updates Cloudflare's IP's and parses them to NGINX. This allows NGINX's logs to see the actual visitor IP.

# How do I set this script up?
Download the script

```
wget https://git.io/vAa8m -O /opt/scripts/cloudflare-update-ranges.sh
cd /opt/scripts/cloudflare-update-ranges.sh
chmod +x cloudflare-update-ranges.sh
```

We need to modify your `nginx.conf` to use the IP's provided by the script.

```
sudo nano /etc/nginx/conf.d/cloudflare.conf
```
Enter the following: (This include path should match your `CLOUDFLARE_NGINX_CONFIG` configuration value in the script)
```
# Location of file containing CloudFlare IP addresses
include /etc/nginx/cloudflare;
```
Then run:
```
sudo service nginx reload
```

## Automate the script 
```
sudo crontab -e
```
Then enter the following (This will need to be updated to wherever you save the script file):
```
0 0 * * * /opt/scripts/cloudflare-update-ranges.sh > /dev/null 2>&1
```
