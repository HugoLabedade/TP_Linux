# TP3 : systemd
## I. Services systemd
### 1. Intro

J'ai affiché le nombre de services systemd de ma machine : 
```
[vagrant@tp3 ~]$ sudo systemctl list-unit-files -t service -a | grep service | wc -l
155
```

De même pour les services "running" : 
```
[vagrant@tp3 ~]$ sudo systemctl list-units -t service -a | grep running | wc -l
18
```

Pour les services "failed" ou "exited" :
```
[vagrant@tp3 ~]$ sudo systemctl list-units -t service -a | grep failed | wc -l
1
[vagrant@tp3 ~]$ sudo systemctl list-units -t service -a | grep exited | wc -l
16
```

Et enfin pour les "enabled" : 
```
[vagrant@tp3 ~]$ sudo systemctl list-unit-files -t service -a | grep enabled | wc -l
32
```

### 2. Analyse d'un service

J'ai effectué un cat de nginx.service et j'en ai déduis grâceau commentaire en début de fichier que le path est /usr/lib/systemd/system/nginx.service

```
[vagrant@tp3 ~]$ sudo systemctl cat nginx.service
# /usr/lib/systemd/system/nginx.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong 
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
```

ExecStart= est la commande effectué par ce fichier lorsqu'on appelle le service avec la commande systemctl start "x"
ExecStartPre= : Commandes supplémentaires exécutées avant ou après la commande dans ExecStart = respectivement. La syntaxe est la même que pour ExecStart = sauf que plusieurs lignes de commande sont autorisées et que les commandes sont exécutées l'une après l'autre, en série.
PIDFile est le chemin référent au fichier PID du service 
Type= configure le type du process au démarrage pour ce service (ca peut être : simple, exec, forking, oneshot, dbus, notify ou idle)
Execreload= est la commande a réaliser pour déclencher un reload du sevice
Description= un nom "human readable" du service
After= assure que les unités listées soient bien lancées avant que le service soit bootée

J'ai réussi à voir tous les services qui ont la dite ligne

```
[vagrant@tp3 ~]$ grep -inr WantedBy=multi-user.target /usr/lib/systemd/system/
/usr/lib/systemd/system/fstrim.timer:11:WantedBy=multi-user.target
/usr/lib/systemd/system/machines.target:17:WantedBy=multi-user.target
/usr/lib/systemd/system/remote-cryptsetup.target:16:WantedBy=multi-user.target
/usr/lib/systemd/system/remote-fs.target:16:WantedBy=multi-user.target
/usr/lib/systemd/system/rpcbind.service:17:WantedBy=multi-user.target
/usr/lib/systemd/system/rdisc.service:11:WantedBy=multi-user.target
/usr/lib/systemd/system/brandbot.path:9:WantedBy=multi-user.target
/usr/lib/systemd/system/tcsd.service:10:WantedBy=multi-user.target
/usr/lib/systemd/system/sshd.service:17:WantedBy=multi-user.target
/usr/lib/systemd/system/rhel-configure.service:18:WantedBy=multi-user.target
/usr/lib/systemd/system/rsyslog.service:19:WantedBy=multi-user.target
/usr/lib/systemd/system/irqbalance.service:10:WantedBy=multi-user.target
/usr/lib/systemd/system/cpupower.service:13:WantedBy=multi-user.target
/usr/lib/systemd/system/crond.service:14:WantedBy=multi-user.target
/usr/lib/systemd/system/rpc-rquotad.service:14:WantedBy=multi-user.target
/usr/lib/systemd/system/wpa_supplicant.service:13:WantedBy=multi-user.target
/usr/lib/systemd/system/chrony-wait.service:18:WantedBy=multi-user.target
/usr/lib/systemd/system/chronyd.service:19:WantedBy=multi-user.target
/usr/lib/systemd/system/NetworkManager.service:26:WantedBy=multi-user.target
/usr/lib/systemd/system/ebtables.service:11:WantedBy=multi-user.target
/usr/lib/systemd/system/gssproxy.service:17:WantedBy=multi-user.target
/usr/lib/systemd/system/tuned.service:15:WantedBy=multi-user.target
/usr/lib/systemd/system/firewalld.service:22:WantedBy=multi-user.target
/usr/lib/systemd/system/nfs-client.target:15:WantedBy=multi-user.target
/usr/lib/systemd/system/nfs-server.service:37:WantedBy=multi-user.target
/usr/lib/systemd/system/rsyncd.service:10:WantedBy=multi-user.target
/usr/lib/systemd/system/nginx.service:21:WantedBy=multi-user.target
/usr/lib/systemd/system/vmtoolsd.service:18:WantedBy=multi-user.target
/usr/lib/systemd/system/postfix.service:17:WantedBy=multi-user.target
/usr/lib/systemd/system/auditd.service:32:WantedBy=multi-user.target
```

### 3. Création d'un service

J'ai créé un petit service qui donne la date en looping pour qu'il reste actif et je peux en effet le lancer :
```
[Unit]
Description=Date

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/test_service.sh

[Install]
WantedBy=multi-user.target
```

```
[vagrant@tp3 ~]$ sudo systemctl status monservice
● monservice.service - Example systemd service.
   Loaded: loaded (/etc/systemd/system/monservice.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-07 12:21:43 UTC; 1s ago
 Main PID: 2582 (bash)
   CGroup: /system.slice/monservice.service
           ├─2582 /bin/bash /usr/bin/test_service.sh
           └─2584 sleep 30

Oct 07 12:21:43 tp3.b2 systemd[1]: Started Example systemd service..
Oct 07 12:21:44 tp3.b2 bash[2582]: 2020-10-07 12:21:44
Oct 07 12:21:44 tp3.b2 bash[2582]: Looping...
```

#### A. Serveur web

J'ai créé mon ptit service appelé serveur_http qui ouvre le port au démarrage et lance le serveur web et ferme le port au stop du service :
```
[vagrant@tp3 ~]$ sudo systemctl status serveur_http
● serveur_http.service - ptit serveur web avec python3
   Loaded: loaded (/etc/systemd/system/serveur_http.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-07 12:55:42 UTC; 9s ago
  Process: 3176 ExecStartPre=/usr/bin/firewall-cmd --reload (code=exited, status=0/SUCCESS)
  Process: 3175 ExecStartPre=/usr/bin/firewall-cmd --add-port=8080/tcp --permanent (code=exited, status=0/SUCCESS)
 Main PID: 3204 (python3)
   CGroup: /system.slice/serveur_http.service
           └─3204 /usr/bin/python3 -m http.server 8080

Oct 07 12:55:41 tp3.b2 systemd[1]: Starting ptit serveur web avec python3...
Oct 07 12:55:42 tp3.b2 firewall-cmd[3175]: success
Oct 07 12:55:42 tp3.b2 firewall-cmd[3176]: success
Oct 07 12:55:42 tp3.b2 systemd[1]: Started ptit serveur web avec python3.
[vagrant@tp3 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 83526sec preferred_lft 83526sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:c6:bd:92 brd ff:ff:ff:ff:ff:ff
    inet 192.168.3.11/24 brd 192.168.3.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec6:bd92/64 scope link
       valid_lft forever preferred_lft forever
[vagrant@tp3 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources:
  services: dhcpv6-client ssh
  ports: 8080/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:

[vagrant@tp3 ~]$ sudo systemctl stop serveur_http.service 
[vagrant@tp3 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
[vagrant@tp3 ~]$ sudo systemctl start serveur_http
[vagrant@tp3 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
[vagrant@tp3 ~]$ sudo systemctl status serveur_http
● serveur_http.service - ptit serveur web avec python3
   Loaded: loaded (/etc/systemd/system/serveur_http.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-07 12:58:54 UTC; 24s ago
  Process: 3245 ExecStop=/usr/bin/firewall-cmd --reload (code=exited, status=0/SUCCESS)
  Process: 3244 ExecStop=/usr/bin/firewall-cmd --remove-port=8080/tcp --permanent (code=exited, status=0/SUCCESS) 
  Process: 3288 ExecStartPre=/usr/bin/firewall-cmd --reload (code=exited, status=0/SUCCESS)
  Process: 3287 ExecStartPre=/usr/bin/firewall-cmd --add-port=8080/tcp --permanent (code=exited, status=0/SUCCESS)
 Main PID: 3316 (python3)
   CGroup: /system.slice/serveur_http.service
           └─3316 /usr/bin/python3 -m http.server 8080

Oct 07 12:58:52 tp3.b2 systemd[1]: Starting ptit serveur web avec python3...
Oct 07 12:58:53 tp3.b2 firewall-cmd[3287]: success
Oct 07 12:58:54 tp3.b2 firewall-cmd[3288]: success
Oct 07 12:58:54 tp3.b2 systemd[1]: Started ptit serveur web avec python3.
[vagrant@tp3 ~]$ sudo firewall-cmd --list-all | grep ports
  ports: 8080/tcp
  forward-ports:
  source-ports:
[vagrant@tp3 ~]$ curl 192.168.3.11:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="swapfile">swapfile</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

#### B. Sauvegarde

J'ai créé un user "serveur" que j'ai attribué au service backup et j'ai fait tout le necessaire pour le service, voila la ptite démo : 
```
[vagrant@tp3 ~]$ sudo systemctl status backup
● backup.service
   Loaded: loaded (/etc/systemd/system/backup.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Sat 2020-10-10 10:00:44 UTC; 2min 47s ago
  Process: 2788 ExecStartPost=/bin/backupPost.sh (code=exited, status=0/SUCCESS)
  Process: 2787 ExecStart=/bin/backup.sh (code=exited, status=0/SUCCESS)
  Process: 2786 ExecStartPre=/bin/backupPre.sh (code=exited, status=0/SUCCESS)
 Main PID: 2787 (code=exited, status=0/SUCCESS)

Oct 10 10:00:44 tp3.b2 systemd[1]: Starting backup.service...
Oct 10 10:00:44 tp3.b2 systemd[1]: Started backup.service.
```


J'ai également créé un timer pour pouvoir lancer le service backup toutes les heures :
```
[vagrant@tp3 ~]$ sudo systemctl start backup.timer
[vagrant@tp3 ~]$ sudo systemctl status backup.timer
● backup.timer - un timer qui va faire des sauvegardes toutes les heures
   Loaded: loaded (/etc/systemd/system/backup.timer; enabled; vendor preset: disabled)
   Active: active (waiting) since Sat 2020-10-10 10:04:37 UTC; 7s ago

Oct 10 10:04:37 tp3.b2 systemd[1]: Started un timer qui va faire des sauvegardes toutes les heures.
[vagrant@tp3 ~]$ sudo systemctl enable backup.timer
[vagrant@tp3 ~]$ systemctl list-timers
NEXT                         LEFT       LAST                         PASSED    UNIT                         ACTIVATES
Sat 2020-10-10 11:00:00 UTC  54min left n/a                          n/a       backup.timer                 backup.service
Sun 2020-10-11 09:50:45 UTC  23h left   Sat 2020-10-10 09:50:45 UTC  14min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
```


## II. Autres features
### 1. Gestion de boot

J'ai créé une nouvelle vm sur centos8 : 
```
[vagrant@node ~]$ sudo cat /etc/centos-release
CentOS Linux release 8.0.1905 (Core)
```
```
[vagrant@node ~]$ systemd-analyze plot > file.svg
```
Pour récupérer le diagramme du boot

Ensuite, j'ai remarqué que mes 3 services les plus lents sont : 
- mon service serveur_hhtp
- swapfile.swap
- le service firewalld.service


###2. Gestion de l'heure

Mon timedatectl m'indique que:
- mon fuseau horaire est UTC 
- je suis synchro sur un serveur ntp depuis la ligne "ntp service: active": 
```
[vagrant@node ~]$ systemd-analyze plot > file.svg
[vagrant@node ~]$ timedatectl
               Local time: Sat 2020-10-08 10:34:07 UTC
           Universal time: Sat 2020-10-08 10:34:07 UTC
                 RTC time: Sat 2020-10-08 10:34:07
                Time zone: UTC (UTC, +0000)
System clock synchronized: no
              NTP service: active
          RTC in local TZ: no
```

Pour me mettre au niveau de la France il faut run ces commandes : 
```
[vagrant@node ~]$ timedatectl list-timezones | grep Paris
Europe/Paris
[vagrant@node ~]$ sudo timedatectl set-timezone Europe/Paris
[vagrant@node ~]$  sudo timedatectl
               Local time: Sat 2020-10-10 12:38:37 CEST
           Universal time: Sat 2020-10-10 10:38:37 UTC
                 RTC time: Sat 2020-10-10 10:38:37
                Time zone: Europe/Paris (CEST, +0200)
System clock synchronized: no
              NTP service: active
          RTC in local TZ: no
```
### 3. Gestion des noms et de la résolution de noms

Pour afficher mon hostname depuis hostnamectl on fait : 
```
[vagrant@node ~]$ hostnamectl
   Static hostname: node.tp3.b2
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 24d6e472a753462eaf542a34d2c1f304
           Boot ID: 072e50ee950740aeab4b3f7cd4a762e8
    Virtualization: oracle
  Operating System: CentOS Linux 8 (Core)
       CPE OS Name: cpe:/o:centos:centos:8
            Kernel: Linux 4.18.0-80.el8.x86_64
      Architecture: x86-64
```
J'ai donc changé mon hostname facilement : 
```
[vagrant@node ~]$ sudo hostnamectl set-hostname ekip
[vagrant@node ~]$ hostnamectl
   Static hostname: ekip
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 24d6e472a753462eaf542a34d2c1f304
           Boot ID: 072e50ee950740aeab4b3f7cd4a762e8
    Virtualization: oracle
  Operating System: CentOS Linux 8 (Core)
       CPE OS Name: cpe:/o:centos:centos:8
            Kernel: Linux 4.18.0-80.el8.x86_64
      Architecture: x86-64
```

