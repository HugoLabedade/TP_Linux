#!/bin/sh

echo "192.168.2.22 node2.tp2.b2" >> /etc/hosts

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https