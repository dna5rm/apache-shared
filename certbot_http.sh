#!/bin/env -S bash
## Fetch SSL cert using certbot w/no http server
#
# Crontab Example:
#
# 0 1 * * 7       [[ -x "/opt/apache-shared/certbot_http.sh" ]] && { "/opt/apache-shared/certbot_http.sh" "test.domain.local"; }
#

# Enable for debuging
# set -x

cert_domain="${1}"

# Verify script requirements
for req in certbot openssl python3
 do type ${req} >/dev/null 2>&1 || { echo >&2 "$(basename "${0}"): I require ${req} but it's not installed. Aborting."; exit 1; }
done

# Die if not Root
if ! [[ $(id -u) = 0 ]]
 then echo "$(basename ${0}): Must be ran as $(id -u 0 -n)!"
      exit 1

 # Certbot Renewal
 elif [[ ! -z "${cert_domain}" ]] && [[ -z "$(ss -tulwn | grep 'LISTEN.*:80 ')" ]]
  then # No cert refresh (8d)
       if openssl x509 -checkend 691200 -noout -in "/etc/letsencrypt/live/${cert_domain}/cert.pem" > /dev/null
        then printf "%.0s#" {1..80}
             printf "\r### /etc/letsencrypt/live/${cert_domain}/*.pem ###\n\n"
             cat "/etc/letsencrypt/live/${cert_domain}/README"

        # Cert refresh
        else http_root="/tmp/$(basename ${0%.*}).webroot/"
             install -m 644 -D /dev/null -T "${http_root}/index.html"

             # Run temp http.server on port 80 (3min)
             if timeout 180 python3 -m http.server --bind :: --directory "${http_root}" 80 &
              then certbot certonly --webroot --webroot-path "${http_root}" -d "${cert_domain}"
             fi

            # Cleanup when finished
            if [[ -d "${http_root}" ]]
             then kill "$(lsof -t -i:80)"
                  rm -rf "${http_root}"
            fi

            # Restart apache2
            if [[ -e "/etc/init.d/apache2" ]]
             then /etc/init.d/apache2 restart
            fi
       fi && [[ -x "/opt/apache-shared/certbot_pem.sh" ]] && { "/opt/apache-shared/certbot_pem.sh"; }

 else echo "$(basename ${0}): Certificate issue or TCP/80 is already listening..."
fi
