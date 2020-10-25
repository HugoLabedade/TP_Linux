#!/bin/sh
#Hugo
#24/10/2020
#ptit script pour l'installe de gitea


#les prérequis comme d'hab
yum install -y wget
yum install -y git

firewall-cmd --add-port=3000/tcp --permanent
firewall-cmd --reload

wget -O gitea https://dl.gitea.io/gitea/1.12.5/gitea-1.12.5-linux-amd64
chmod +x gitea

adduser --system --shell /bin/bash --comment 'Git Version Control' --user-group --create-home git
passwd -f -u git

mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

#les routes
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 node.gitea node1
192.168.4.12 node.mariadb node.mariadb
192.168.4.13 node.nginx node.nginx
192.168.4.14 node.nfs node.nfs" > /etc/hosts



#on fait le service pour gitea sans commentaire
echo "[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
[Service]
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gitea.service

systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

yum install -y nfs-utils
mkdir /mnt/gitea
mount 192.168.4.14:/home/vagrant/gitea /mnt/gitea


#pour netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
echo 'SEND_DISCORD="YES"
DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/769959176344174602/WSwIRdgey3BMfzLIe653as1xTYXwvISVoJ77ejmYGh3-_1ZilQriRcX_VHd_H7bXEYa4"
DEFAULT_RECIPIENT_DISCORD="alarms"' > /etc/netdata/health_alarm_notify.conf