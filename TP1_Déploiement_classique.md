# TP1 : Déploiement classique

## 0. Prérequis

- J'ai partitionné les nouveaux disques durs avec LVM sur le vg "data1" : 

```
[root@localhost ~]# sudo lvcreate -L 2G data1 -n disk1
  Logical volume "disk1" created.
[root@localhost ~]# sudo lvcreate -L 3G data1 -n disk2
  Volume group "data1" has insufficient free space (767 extents): 768 required.
[root@localhost ~]# sudo lvcreate -l 100%FREE data1 -n disk2
  Logical volume "disk2" created.
  
[root@localhost ~]# lvs
  LV    VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root  centos -wi-ao----  <6.20g
  swap  centos -wi-ao---- 820.00m
  disk1 data1  -wi-a-----   2.00g
  disk2 data1  -wi-a-----  <3.00g
  ```
  Création des dossiers de montage : 
  ```
  [root@localhost ~]# mkdir /srv/site1
[root@localhost ~]# mkdir /srv/site2
```

- Montage des disques durs : 
```
[root@localhost ~]# mount /dev/data1/disk1 /srv/site1
[root@localhost ~]# mount /dev/data1/disk2 /srv/site2
```

Definition du montage automatique au démarrage: 
```
[root@localhost ~]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Thu Jan 30 12:00:43 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/centos-root /                       xfs     defaults        0 0
UUID=594cc377-d158-44af-aca1-3efd317e7fd6 /boot                   xfs     defaults        0 0
/dev/mapper/centos-swap swap                    swap    defaults        0 0
/dev/data1/disk1 /srv/site1 ext4 defaults 0 0
/dev/data1/disk2 /srv/site2 ext4 defaults 0 0
```
Petite verif 
```
[root@localhost ~]# mount -av
/                        : ignored
/boot                    : already mounted
swap                     : ignored
/srv/site1               : already mounted
/srv/site2               : already mounted
```

 - Création de la route par défaut : 
 ```
 [root@localhost ~]# cat /etc/sysconfig/network
# Created by anaconda
GATEWAY=192.168.1.254
```

- Vérification d'accès à internet : 
```
[root@localhost ~]# dig google.com@8.8.8.8

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-9.P2.el7 <<>> google.com@8.8.8.8
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 38140
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com\@8.8.8.8.           IN      A

;; Query time: 10 msec
;; SERVER: 10.33.10.148#53(10.33.10.148)
;; WHEN: Wed Sep 23 17:55:40 CEST 2020
;; MSG SIZE  rcvd: 47
```

- J'ai accès au reseau local en ajoutant une route statique sur mes vm pour qu'elles puissent communiquer entre elles : 
```
[root@node1 ~]# ip route add 192.168.1.12 via 192.168.1.254 dev enp0s8
```
petite verif 
```
[root@node1 ~]# ip r s
default via 10.0.2.2 dev enp0s3 proto dhcp metric 100
default via 192.168.1.254 dev enp0s8 proto static metric 101
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
192.168.1.0/24 dev enp0s8 proto kernel scope link src 192.168.1.11 metric 101
192.168.1.12 via 192.168.1.254 dev enp0s8
```

et le ping marche depuis node1 vers node2 :
```
[root@node1 ~]# ping 192.168.1.12
PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
64 bytes from 192.168.1.12: icmp_seq=1 ttl=64 time=0.665 ms
64 bytes from 192.168.1.12: icmp_seq=2 ttl=64 time=1.02 ms
64 bytes from 192.168.1.12: icmp_seq=3 ttl=64 time=1.17 ms
64 bytes from 192.168.1.12: icmp_seq=4 ttl=64 time=1.10 ms
^C
--- 192.168.1.12 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 0.665/0.991/1.170/0.197 ms
```

et à l'inverse, node 2 peut ping vers node 1 : 
```
[root@node2 ~]# ping 192.168.1.11
PING 192.168.1.11 (192.168.1.11) 56(84) bytes of data.
64 bytes from 192.168.1.11: icmp_seq=1 ttl=64 time=0.879 ms
64 bytes from 192.168.1.11: icmp_seq=2 ttl=64 time=0.906 ms
64 bytes from 192.168.1.11: icmp_seq=3 ttl=64 time=0.844 ms
64 bytes from 192.168.1.11: icmp_seq=4 ttl=64 time=1.00 ms
64 bytes from 192.168.1.11: icmp_seq=5 ttl=64 time=0.993 ms
64 bytes from 192.168.1.11: icmp_seq=6 ttl=64 time=1.08 ms
64 bytes from 192.168.1.11: icmp_seq=7 ttl=64 time=0.571 ms
^C
--- 192.168.1.11 ping statistics ---
7 packets transmitted, 7 received, 0% packet loss, time 6015ms
rtt min/avg/max/mdev = 0.571/0.897/1.082/0.156 ms
```

- J'avais, à l'avance, changé le hostname des machines : 
```
[root@node1 ~]# cat /etc/hostname
node1.tp1.b2
[root@node2 ~]# cat /etc/hostname
node2.tp1.b2
```

- J'ai changé les fichiers /etc/hosts pour pouvoir joindre les vm grâce à leur hostname : 
```
[root@node1 ~]# ping node2
PING node2.tp1.b2 (192.168.1.12) 56(84) bytes of data.
64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=1 ttl=64 time=0.936 ms
64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=2 ttl=64 time=0.957 ms
64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=3 ttl=64 time=1.06 ms
64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=4 ttl=64 time=0.953 ms
64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=5 ttl=64 time=1.05 ms
^C
--- node2.tp1.b2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4025ms
rtt min/avg/max/mdev = 0.936/0.993/1.067/0.068 ms
```
```
[root@node2 ~]# ping node1
PING node1.tp1.b2 (192.168.1.11) 56(84) bytes of data.
64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=1 ttl=64 time=0.549 ms
64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=2 ttl=64 time=1.00 ms
64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=3 ttl=64 time=0.817 ms
^C
--- node1.tp1.b2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.549/0.791/1.008/0.189 ms
```

- J'ai créé un user "admin" sur mes vm qui peut utiliser les commandes sudo en tant que root : 
```
[root@node1 ~]# adduser admin
[root@node1 ~]# passwd admin
Changing password for user admin.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
[root@node1 ~]# usermod -aG wheel admin
[root@node1 ~]# su - admin
[admin@node1 ~]$ ls -al /root
ls: cannot open directory /root: Permission denied
[admin@node1 ~]$ sudo !!
sudo ls -al /root

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for admin:
total 28
dr-xr-x---.  2 root root  135 Mar  9  2020 .
dr-xr-xr-x. 17 root root  224 Jan 30  2020 ..
-rw-------.  1 root root 1487 Jan 30  2020 anaconda-ks.cfg
-rw-------.  1 root root  126 Sep 23 17:57 .bash_history
-rw-r--r--.  1 root root   18 Dec 29  2013 .bash_logout
-rw-r--r--.  1 root root  176 Dec 29  2013 .bash_profile
-rw-r--r--.  1 root root  176 Dec 29  2013 .bashrc
-rw-r--r--.  1 root root  100 Dec 29  2013 .cshrc
-rw-r--r--.  1 root root  129 Dec 29  2013 .tcshrc
```

- Enfin, tous les ports sont fermés sauf ceux indispensables pour ce tp : 
```
[admin@node1 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: ssh dhcpv6-client
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
  ```
  ```
  [admin@node2 ~]$ sudo firewall-cmd --list-all
[sudo] password for admin:
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: ssh dhcpv6-client
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
  ```
  
 
 ## I. Setup serveur Web
 
 - J'ai installé et démarré le serveur web NGINX : 
 
```
[admin@node1 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-09-24 15:56:18 CEST; 1min 19s ago
  Process: 4989 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4986 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 4985 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4991 (nginx)
   CGroup: /system.slice/nginx.service
           ├─4991 nginx: master process /usr/sbin/nginx
           └─4992 nginx: worker process

Sep 24 15:56:18 node1.tp1.b2 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Sep 24 15:56:18 node1.tp1.b2 nginx[4986]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Sep 24 15:56:18 node1.tp1.b2 nginx[4986]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Sep 24 15:56:18 node1.tp1.b2 systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
Sep 24 15:56:18 node1.tp1.b2 systemd[1]: Started The nginx HTTP and reverse proxy server.
```

- J'ai généré la clé et le cert pour le serveur web en https : 
```
[admin@node1 ~]$ openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.cr
Generating a 2048 bit RSA private key
.......+++
.........................+++
writing new private key to 'server.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:
State or Province Name (full name) []:
Locality Name (eg, city) [Default City]:
Organization Name (eg, company) [Default Company Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:
Email Address []:
[admin@node1 ~]$ ls
index.html  server.cr  server.key
```

- J'ai mis les fichiers dans le dossier nginx : 
```
[admin@node1 ~]$ sudo mv server.cr /etc/nginx
[admin@node1 ~]$ sudo mv server.key /etc/nginx
[admin@node1 ~]$
````

- J'ai donné les bonne permissions (755) aux fichiers  pour que le serveur web puisse les executer : 
```
[admin@node1 ~]$ ls -al /srv/site1/
total 24
drwxr-xr-x. 3 root root   4096 Sep 24 16:54 .
drwxr-xr-x. 4 root root     32 Sep 23 16:40 ..
-rwxr-xr-x. 1  755 admin    19 Sep 24 17:07 index.html
drwxr-xr-x. 2 root root  16384 Sep 23 16:33 lost+found

[admin@node1 ~]$ ls -al /srv/site2/
total 20
drwxr-xr-x. 3  755 root   4096 Sep 24 16:21 .
drwxr-xr-x. 4 root root     32 Sep 23 16:40 ..
-rwxr-xr-x. 1  755 admin     0 Sep 24 16:21 index.html
drwxr-xr-x. 2  755 root  16384 Sep 23 16:38 lost+found
```

- J'arrive normalement a curl les sites : 
```
[admin@node1 ~]$ curl -L node1.tp1.b2/site1
<h1> ekip  1 </h1>
[admin@node1 ~]$ curl -L node1.tp1.b2/site2
<h1> ekip 2 </h1>
```

et également depuis l'autre vm : 
```
[admin@node2 ~]$ curl -L node1.tp1.b2/site1
<h1> ekip  1 </h1>
[admin@node2 ~]$ curl -L node1.tp1.b2/site2
<h1> ekip 2 </h1>
````

## II. Script de sauvegarde

- Pour le scrip, on crée tout d'abord un user appelé backup : 
```
[admin@node1 ~]$ sudo adduser backup
[admin@node1 ~]$
```

On écrit ensuite le script de sauvegarde : 
```
#!/bin/sh

#HugoTroBo
#28/09/2020
#un script de backup pour les sites qu'on a cré


##################
#
# SCRIPT DE SAUVEGARDE DE FICHIER POUR LE TP1
#
##################


# les fichiers a sauvegarder qu'on rentre en argument
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

delete_file() {
    if [[ $(ls -lt backup/ | grep ${backup_file} | wc -w) -gt 7 ]]
    then
         ls -t backup/ | grep ${backup_file} | tail -n 1 | xargs rm -f
    fi
}

backup
delete_file
exit 0
```

- J'ai installé et configuré crontab : 
```
[admin@node1 ~]$ crontab -l
01 * * * * ./tp1_backup.sh /srv/site1
01 * * * * ./tp1_backup.sh /srv/site2
```