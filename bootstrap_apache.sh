#!/bin/env bash

# opt location
optdir="/opt/apache-shared"

# Packages to install
pkgs=($(echo $(tr ' ' '\n' <<< "apache2 certbot libapache2-mod-php php-yaml" | sort -u)))

# Apache2 conf files
conf=( "localized-error-pages.conf" )

# Apache2 mods enabled
mods=( "alias" "autoindex" "ssl" "userdir" )

# main script
if [[ ${UID:-1000} != 0 ]]
 then echo "$(basename ${0}): Run as root!"
 else [[ "$(lsb_release -i | awk '{print tolower($NF)}')" != "debian" ]] && {
       echo "$(basename ${0}): Debian not found!"
      } || { admin="$(stat -c "%U" "${0}")"

       ## $optdir symlink
       [[ ! -s "${optdir}" ]] && {
        echo; printf "$(basename ${0}): Creating Symlink [%s]\n" "${optdir}"
        ln -fs "$(dirname $(readlink -f ${0}))" "${optdir}"
       }

       ## Upgrade & install packages
       [[ ! -z "${pkgs}" ]] && {
        echo; printf "$(basename ${0}): Installing [%s]\n" ${pkgs[@]}
        echo; yes | apt-get install ${pkgs[@]}
       }

       ### Configure Apache2
       [[ ! -d "/etc/apache2" ]] && {
        echo "$(basename ${0}): unable to find /etc/apache2"
       } || {

        #### Apache2: ports.conf
        [[ ! -f "/etc/apache2/ports.conf" ]] && {
         echo "$(basename ${0}): unable to find /etc/apache2/ports.conf"
        } || {
         echo; printf "$(basename ${0}): Update [%s]\n" "ports.conf"
         sed -e '/^Listen\ 80$/ s/^#*/#/' -i /etc/apache2/ports.conf
        }

        #### Apache2: php.conf
        [[ ! -f "$(find /etc/apache2/mods-available/php*.conf)" ]] && {
         echo "$(basename ${0}): unable to find find php.conf"
        } || {
         echo; printf "$(basename ${0}): Update [%s]\n" "php.conf"
         sed -e '/php_admin_flag.*Off$/ s/Off$/On/' -i $(find /etc/apache2/mods-available/php*.conf)
        }

        #### Apache2: conf-enabled
        [[ ! -d "/etc/apache2/conf-enabled" ]] && {
         echo "$(basename ${0}): unable to find /etc/apache2/conf-enabled"
        } || {
         for file in ${conf[@]}
          do echo; printf "$(basename ${0}): conf-enabled [%s]\n" "${file}"
             ln -fs "${optdir}/${file}" "/etc/apache2/conf-enabled/${file}"
         done
        }

        #### Apache2: mods-enabled
        [[ ! -d "/etc/apache2/mods-enabled" ]] && {
         echo "$(basename ${0}): unable to find /etc/apache2/mods-enabled"
        } || {
         for mod in ${mods[@]}
          do echo; printf "$(basename ${0}): mods-enabled [%s]\n" "${mod}"
             a2enmod "${mod}"
             [[ -f "${optdir}/${mod}.conf" ]] && {
              ln -fs "${optdir}/${mod}.conf" "/etc/apache2/mods-enabled/${mod}.conf"
             }
         done
        }

        #### Apache2: sites-enabled
        [[ ! -d "/etc/apache2/sites-enabled" ]] && {
         echo "$(basename ${0}): unable to find /etc/apache2/sites-enabled"
        } || {

         ##### Disable default site
         [[ -s "/etc/apache2/sites-enabled/000-default.conf" ]] && {
          a2dissite 000-default
         }

         ##### Enable ssl-default
         [[ ! -s "/etc/apache2/sites-enabled/000-default-ssl.conf" ]] && {
          ln -fs "/etc/apache2/sites-available/default-ssl.conf" "/etc/apache2/sites-enabled/000-default-ssl.conf"
         }
        }

        #### Apache2: /var/www/html
        [[ ! -d "/var/www/html" ]] && {
         echo "$(basename ${0}): unable to find /var/www/html"
        } || {
         ##### Apache2: Delete default page
         [[ -f "/var/www/html/index.html" ]] && {
          grep "Apache2 Debian Default Page" "/var/www/html/index.html" > /dev/null 2>&1 &&\
           rm -f "/var/www/html/index.html"
         }

         ##### Apache2: /srv/www
         chown "${admin}" "/var/www/html"
         [[ ! -s "/srv/www" ]] && {
          ln -fs "/var/www/html" "/srv/www"
         }

         ##### Apache2: public_html
         [[ ! -e "/home/${admin}/public_html" ]] && {
          ln -fs "/var/www/html" "/home/${admin}/public_html"
         }
        }

       }
      }
fi
