#!/bin/bash
#Hugo
#24/10/2020
#ptit script pour mettre en place mariadb

#les prérequis 
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload

#on ajoute les routes
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 node2.db node2
192.168.4.11 node.gitea node.gitea
192.168.4.13 node.nginx node.nginx
192.168.4.14 node.nfs node.nfs" > /etc/hosts


#on fait la config sql pour mariadb et on la range bien gentillement
echo "[mysqld]
bind-address = 192.168.4.11
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd
[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
#
# include all files from the config directory
#
!includedir /etc/my.cnf.d" > /etc/my.cnf


# https://docs.gitea.io/en-us/database-prep/
# SET old_passwords=0;
# CREATE USER 'gitea'@'192.168.4.11' IDENTIFIED BY 'gitea';
# CREATE DATABASE giteadb CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci';
# GRANT ALL PRIVILEGES ON giteadb.* TO 'gitea'@'192.168.4.11';
# FLUSH PRIVILEGES;

yum install -y nfs-utils
mkdir /mnt/mariadb
mount 192.168.4.14:/home/vagrant/db /mnt/mariadb


#pour netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
echo 'SEND_DISCORD="YES"
DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/769959176344174602/WSwIRdgey3BMfzLIe653as1xTYXwvISVoJ77ejmYGh3-_1ZilQriRcX_VHd_H7bXEYa4"
DEFAULT_RECIPIENT_DISCORD="alarms"' > /etc/netdata/health_alarm_notify.conf
