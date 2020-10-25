#!/bin/sh
#Hugo
#25/10/2020
#ptit script pour le serveur nfs et on fait attention au firewall


#les habitudes des prérequis
yum install -y nfs-utils

systemctl start nfs-server rpcbind
systemctl enable nfs-server rpcbind

mkdir gitea
mkdir db
mkdir nginx

chmod 777 ./gitea
chmod 777 ./db
chmod 777 ./nginx


echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 node4.nfs node4
192.168.4.11 node.gitea node.gitea
192.168.4.12 node.db node.db
192.168.4.13 node.nginx node.ngninx" > /etc/hosts



echo "/home/vagrant/gitea 192.168.4.11(rw,sync,no_root_squash)
/home/vagrant/db 192.168.4.12(rw,sync,no_root_squash)
/home/vagrant/nginx 192.168.4.13(rw,sync,no_root_squash)" > /etc/exports

exportfs -r

#on fait attention au firewall
firewall-cmd --permanent --add-service mountd
firewall-cmd --permanent --add-service rpc-bind
firewall-cmd --permanent --add-service nfs
firewall-cmd --reload
chmod 777 ./gitea

#netdata takapté
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
echo 'SEND_DISCORD="YES"
DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/769959176344174602/WSwIRdgey3BMfzLIe653as1xTYXwvISVoJ77ejmYGh3-_1ZilQriRcX_VHd_H7bXEYa4"
DEFAULT_RECIPIENT_DISCORD="alarms"' > /etc/netdata/health_alarm_notify.conf