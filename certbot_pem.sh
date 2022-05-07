#!/bin/bash
## Generate PFX files from certbot

# Enable for debuging
# set -x

# Verify script requirements
for req in openssl
 do type ${req} >/dev/null 2>&1 || { echo >&2 "$(basename "${0}"): I require ${req} but it's not installed. Aborting."; exit 1; }
done

# Die if not Root
if ! [[ $(id -u) = 0 ]]
 then echo "$(basename ${0}): Must be ran as $(id -u 0 -n)!"
      exit 1

 else for dir in $(find /etc/letsencrypt/live/* -type d)
       do domain="$(basename ${dir,,})"
          passwd="$(echo -n ${domain} | base64 | cut -c 1-30)"

          echo "${domain} (${passwd})"

          # Generate pfx w/password
          openssl pkcs12 -export -passout pass:${passwd} \
           -certfile "${dir}/chain.pem" \
           -inkey "${dir}/privkey.pem" \
           -in "${dir}/cert.pem" \
           -out "/srv/${domain}.pfx"

          # Generate pem w/password
          openssl rsa -des -passout pass:${passwd} \
           -in "${dir}/privkey.pem" \
           -out "/srv/${domain}.pem" 2> /dev/null

          # Set file ownership & permissions
          [[ -e "/srv/${domain}.pem" ]] || [[ -e "/srv/${domain}.pfx" ]] && {
           chmod 600 "/srv/${domain}.p"*
           chown "$(stat -c "%U" "${0}")" "/srv/${domain}.p"*
          }

      done
fi
