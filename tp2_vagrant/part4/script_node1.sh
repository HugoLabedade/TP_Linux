#!/bin/bash
# petit script pour la créaton de vm
#HugoTroBo
#30/09/2020



# On fait les préliminaires
ip route add 192.168.2.12 via 192.168.2.254 dev eth1

echo "192.168.2.22 node2.tp2.b2 node2" >> /etc/hosts

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https



# On crée le user, on lui donne un mdp, on lui donne des perm et on switch dessus
useradd admin
echo "root" | passwd "admin" --stdin
usermod -aG wheel admin

useradd web -M -s /sbin/nologin

# On crée les dossiers et on donne les perm
mkdir /srv/site1
mkdir /srv/site2

chmod -R 755 /srv/site1
chmod -R 755 /srv/site2
chown -R vagrant:vagrant /srv/site1
chown -R vagrant:vagrant /srv/site1
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=node1.tp2.b2"


# Déplacement du cert et de la clé dans le path standard sous CentOS
mv server.crt /etc/nginx
mv server.key /etc/nginx


# Setup des deux sites web
echo '<h1>Ekip 1</h1>' | tee /srv/site1/index.html
echo '<h1>Ekip 2</h1>' | tee /srv/site2/index.html


# ptite config de nginx (oui echo dans un fichier mais j'ai pas compris le cp..)

echo "worker_processes 1;
error_log nginx_error.log;
events {
    worker_connections 1024;
}
http {
     server {
       listen 80;
        server_name node1.tp1.b2;
        location / {
                return 301 /site1;
        }
        location /site1 {
                alias /srv/site1;
        }
        location /site2 {
                alias /srv/site2;
        }
}
server {
        listen 443 ssl;
        server_name node1.tp2.b2;
        ssl_certificate server.crt;
        ssl_certificate_key server.key;
        location / {
            return 301 /site1;
        }
        location /site1 {
            alias /srv/site1;
        }
        location /site2 {
            alias /srv/site2;
        }
        location ~ /netdata/(?<ndpath>.*) {
            proxy_redirect off;
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_http_version 1.1;
            proxy_pass_request_headers on;
            proxy_set_header Connection 'keep-alive';
            proxy_store off;
            proxy_pass http://netdata/\$ndpath\$is_args\$args;
            gzip on;
            gzip_proxied any;
            gzip_types *;
        }
    }
}" > /etc/nginx/nginx.conf

# ensuite on start le petit bébé et le fait chauffer 180° termostat 8
systemctl start nginx

# mmaintenant on passe au script de sauvegarde rpz tp1 t'as capté chacal

touch backup.sh

mkdir backup 

echo '#!/bin/sh

#HugoTroBo
#28/09/2020
#un script de backup pour les sites quon a cré


##################
#
# SCRIPT DE SAUVEGARDE DE FICHIER POUR LE TP1
#
##################


# les fichiers a sauvegarder quon rentre en argument
backup_file="$(basename $1)"

# il faut mettre les backups ici
destination="./backup"

#la date tavu
date=$(date "+%Y%m%d_%H%M")
archive="${backup_file}_${date}.tar.gz"

#la où il va aller chercher le dossier (oui "file" je sais)
backup_file_path="${1}"


backup () {
        tar -czf "${destination}/${archive}" "${backup_file_path}"

}

# la ptite boucle si jamais ya plus de 7 fichiers 
if [[ $(ls -Al ${destination} | wc -l) > 7 ]]
then
        rm ${destination}/$(ls -tr1 ${destination} | grep -m 1 "")
fi' > tp2.script.sh

chmod +x backup.sh

# on passe a table sur netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

firewall-cmd --add-port=19999/tcp --permanent

firewall-cmd --reload