# Custom Apache Configuration

This is where I store my custom Apache configs / system-wide changes.

## Install Steps

1. Run the bootstrap
   > sudo bootstrap_apache.sh
2. Fetch host certificate
   > sudo certbot_http.sh host.domain.tld
3. Configure crontab to autorenew certificate
   > SHELL=/bin/bash

   > \#\#\# Update Certificate \#\#\#

   > 0 1 * * 7       [[ -e "/opt/apache-shared/certbot_http.sh" ]] && { "/opt/apache-shared/certbot_http.sh" "host.domain.tld"; }
4. Update apache2 SSLCertificateFile
   > sed -e '/ssl-cert-snakeoil.pem$/ s/\/etc\/.*\/ssl-cert-snakeoil.pem/\/etc\/letsencrypt\/live\/host.domain.tld\/fullchain.pem/' -i /etc/apache2/sites-available/default-ssl.conf
5. Update apache2 SSLCertificateKeyFile
   > sed -e '/ssl-cert-snakeoil.key$/ s/\/etc\/.*\/ssl-cert-snakeoil.key/\/etc\/letsencrypt\/live\/host.domain.tld\/privkey.pem/' -i /etc/apache2/sites-available/default-ssl.conf

## Importing Cert on Cisco IOS

>  openssl rsa -des -passout pass:CfZgA2Us0zqQF=zV -in /etc/letsencrypt/live/host.domain.tld/privkey.pem -out host.domain.tld.pem

```
crypto pki trustpoint CA_LETSENCRYPT
    enrollment terminal pem
    exit

crypto pki import CA_LETSENCRYPT pem terminal password CfZgA2Us0zqQF=zV

* paste chain.crt
* paste host.domain.tld.pem
* paste cert.pem
```

## WordPress MySQL account restoration

```
awk -F"'" '/define.*DB/{if($2 == "DB_NAME") {NAME=$4} else if($2 == "DB_USER") {USER=$4} else if($2 == "DB_PASSWORD") {PASS=$4} else if($2 == "DB_HOST") {HOST=$4}}END{print "CREATE USER '\''"USER"'\''@'\''"HOST"'\'' IDENTIFIED BY '\''"PASS"'\'';"; print "GRANT ALL PRIVILEGES ON",NAME".* TO '\''"USER"'\''@'\''"HOST"'\'';"; print "FLUSH PRIVILEGES;"}' wp-config.php
```

## Reference

- [Apaxy](https://github.com/oupala/apaxy "Apaxy")
- [Fancy Index](https://github.com/Vestride/fancy-index "Fancy Index")
- [Bootstrap](https://getbootstrap.com/ "Bootstrap5")
- [File Extensions](http://dotwhat.net/ "File Extension Resource")
