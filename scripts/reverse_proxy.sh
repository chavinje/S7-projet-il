#!/bin/bash

## install web server with php

IP=$(hostname -I | awk '{print $2}')

APT_OPT="-o Dpkg::Progress-Fancy="0" -q -y"
LOG_FILE="/vagrant/logs/install_web.log"
DEBIAN_FRONTEND="noninteractive"

echo "START - install web Server - "$IP

echo "=> [1]: Installing required packages..."
apt-get update $APT_OPT \
  >> $LOG_FILE 2>&1

apt-get install $APT_OPT \
  wget \
  gnupg \
  unzip \
  curl \
  openssl \
  apache2 \
  git \
  sshpass \
  >> $LOG_FILE 2>&1

a2enmod proxy proxy_http ssl

mkdir /etc/ssl/mesCertificat

# Création et déverrouillage de la clé SSL lagence.key
openssl genrsa -des3 -out /etc/ssl/mesCertificat/lagence.key -passout pass:network 2048 >> $LOG_FILE 2>&1
mv /etc/ssl/mesCertificat/lagence.key /etc/ssl/mesCertificat/lagence-pass.key >> $LOG_FILE 2>&1
openssl rsa -in /etc/ssl/mesCertificat/lagence-pass.key \
  -out /etc/ssl/mesCertificat/lagence.key -passin pass:network >> $LOG_FILE 2>&1

# Création du certificat lagence.csr
openssl req -key /etc/ssl/mesCertificat/lagence.key -new -out /etc/ssl/mesCertificat/lagence.csr \
  -subj "/C=FR/ST=France/L=Angers/O=Organization/OU=Organizational Unit/CN=192.168.56.14" >> $LOG_FILE 2>&1

# Signature de la clé par le certificat pour obtenir lagence.crt
openssl x509 -signkey /etc/ssl/mesCertificat/lagence.key -in /etc/ssl/mesCertificat/lagence.csr \
  -req -days 365 -out /etc/ssl/certs/lagence.crt >> $LOG_FILE 2>&1

# Création de la clé et du certificat auto-signés pour l'autorité de certification (CA)
openssl req -x509 -sha256 -days 365 -newkey rsa:2048 -keyout /etc/ssl/mesCertificat/rootCA-pass.key \
  -out /etc/ssl/mesCertificat/rootCA.crt -passout pass:network \
  -subj "/C=FR/ST=France/L=Angers/O=Organization/OU=Organizational Unit/CN=192.168.56.14" >> $LOG_FILE 2>&1

openssl rsa -in /etc/ssl/mesCertificat/rootCA-pass.key \
  -out /etc/ssl/mesCertificat/rootCA.key -passin pass:network >> $LOG_FILE 2>&1

# Configuration des extensions pour le certificat SSL lagence.crt
touch /etc/ssl/mesCertificat/lagence.ext
printf 'authorityKeyIdentifier=keyid,issuer\n' > /etc/ssl/mesCertificat/lagence.ext
printf 'basicConstraints=CA:FALSE\n' >> /etc/ssl/mesCertificat/lagence.ext
printf 'subjectAltName = @alt_names\n' >> /etc/ssl/mesCertificat/lagence.ext
printf '[alt_names]\n' >> /etc/ssl/mesCertificat/lagence.ext
printf 'DNS.1 = 192.168.56.14\n' >> /etc/ssl/mesCertificat/lagence.ext

# Signature du certificat SSL par l'autorité de certification (CA)
openssl x509 -req -CA /etc/ssl/mesCertificat/rootCA.crt -CAkey /etc/ssl/mesCertificat/rootCA.key \
  -in /etc/ssl/mesCertificat/lagence.csr -out /etc/ssl/mesCertificat/lagence.crt -days 365 \
  -CAcreateserial -extfile /etc/ssl/mesCertificat/lagence.ext >> $LOG_FILE 2>&1

echo "Certificat SSl auto-signé prêt"

# Affichage des détails du certificat SSL généré
openssl x509 -text -noout -in /etc/ssl/mesCertificat/lagence.crt >> $LOG_FILE 2>&1


touch /etc/apache2/sites-available/frontend.conf
printf '<VirtualHost *:80>\n' > /etc/apache2/sites-available/frontend.conf
printf '\tServerName groupe6.com\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tServerAlias www.groupe6.com\n\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tProxyPass / http://192.168.56.10:223/\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tProxyPassReverse / http://192.168.56.10:223/\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tProxyRequests Off\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tErrorLog ${APACHE_LOG_DIR}/error.log\n' >> /etc/apache2/sites-available/frontend.conf
printf '\tCustomLog ${APACHE_LOG_DIR}/access.log combined\n' >> /etc/apache2/sites-available/frontend.conf
printf '</VirtualHost>\n\n' >> /etc/apache2/sites-available/frontend.conf


touch /etc/apache2/sites-available/backend.conf
printf '<VirtualHost *:3000>\n' > /etc/apache2/sites-available/backend.conf
printf '\tServerName groupe6.com\n' >> /etc/apache2/sites-available/backend.conf
printf '\tServerAlias www.groupe6.com\n\n' >> /etc/apache2/sites-available/backend.conf
printf '\tProxyPass / http://192.168.56.10:3000/\n' >> /etc/apache2/sites-available/backend.conf
printf '\tProxyPassReverse / http://192.168.56.10:3000/\n' >> /etc/apache2/sites-available/backend.conf
printf '\tProxyRequests Off\n' >> /etc/apache2/sites-available/backend.conf
printf '\tErrorLog ${APACHE_LOG_DIR}/error.log\n' >> /etc/apache2/sites-available/backend.conf
printf '\tCustomLog ${APACHE_LOG_DIR}/access.log combined\n' >> /etc/apache2/sites-available/backend.conf
printf '</VirtualHost>\n' >> /etc/apache2/sites-available/backend.conf


touch /etc/apache2/sites-available/myadmin.conf
printf '<VirtualHost *:228>\n' > /etc/apache2/sites-available/myadmin.conf
printf '\tServerName groupe6.com\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tServerAlias www.groupe6.com\n\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tProxyPass / http://192.168.56.10:228/\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tProxyPassReverse / http://192.168.56.10:228/\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tProxyRequests Off\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tErrorLog ${APACHE_LOG_DIR}/error.log\n' >> /etc/apache2/sites-available/myadmin.conf
printf '\tCustomLog ${APACHE_LOG_DIR}/access.log combined\n' >> /etc/apache2/sites-available/myadmin.conf
printf '</VirtualHost>\n' >> /etc/apache2/sites-available/myadmin.conf

touch /etc/apache2/sites-available/ssl.conf
printf '<IfModule mod_ssl.c>\n' > /etc/apache2/sites-available/ssl.conf
printf '\t<VirtualHost _default_:443>\n ' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tServerName groupe6.com\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tServerAlias www.groupe6.com\n\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tProxyPass / http://192.168.56.10:223/\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tProxyPassReverse / http://192.168.56.10:223/\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tProxyRequests Off\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tErrorLog ${APACHE_LOG_DIR}/error.log\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tCustomLog ${APACHE_LOG_DIR}/access.log combined\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tSSLEngine on\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tSSLCertificateFile      /etc/ssl/mesCertificat/lagence.crt\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\tSSLCertificateKeyFile  /etc/ssl/mesCertificat/lagence.key\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t<FilesMatch "\.(cgi|shtml|phtml|php)$">\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t\tSSLOptions +StdEnvVars\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t</FilesMatch>\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t<Directory /usr/lib/cgi-bin>\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t\tSSLOptions +StdEnvVars\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t\t</Directory>\n' >> /etc/apache2/sites-available/ssl.conf
printf '\t</VirtualHost>\n' >> /etc/apache2/sites-available/ssl.conf
printf '</IfModule>\n' >> /etc/apache2/sites-available/ssl.conf



a2ensite backend.conf frontend.conf myadmin.conf ssl.conf
a2dissite  000-default.conf

sed -i 's/Listen 80/Listen 80\
Listen 3000\
Listen 228/g' /etc/apache2/ports.conf 

#sed -i 's/certs\/ssl-cert-snakeoil.pme/mesCertificat\/rootCA.crt/g' /etc/apache2/sites-available/default-ssl.conf 
#sed -i 's/private\/ssl-cert-snakeoil.key/mesCertificat\/rootCA.key/g' /etc/apache2/sites-available/default-ssl.conf 

systemctl restart apache2

ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N "" -y

sshpass -p "vagrant" ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.10
sshpass -p "vagrant" ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.12

#cp /home/vagrant/.ssh/id_rsa.pub /vagrant/authorized_keys