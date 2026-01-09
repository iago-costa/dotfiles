#!/usr/bin/env bash

set -eu pipefail
IFS=$'\n\t'
setterm --reset

clear
setterm -background red

if [[ "$(id -u)" != "0" ]]; then
    echo "ESTE SCRIPT DEBE SER EJECUTADO COMO ROOT"
    sleep 3
    clear
else
    echo "ESTE SCRIPT SERA EJECUTADO COMO SUPERUSUARIO (ROOT)"
    sleep 3
    clear
fi

sudo apt update
# sudo update-apt-xapian-index
sudo aptitude safe-upgrade
sudo apt install -f
sudo dpkg --configure -a
sudo apt --fix-broken install

# sudo localepurge
sudo update-grub
sudo update-grub2
# sudo aptitude clean
# sudo aptitude autoclean
sudo apt-get autoremove
sudo apt autoremove
sudo apt purge
sudo apt remove

sudo rm -f /var/log/*.old /var/log/*.gz /var/log/apt/* /var/log/auth* /var/log/daemon* /var/log/debug* /var/log/dmesg* /var/log/dpkg* /var/log/kern* /var/log/messages* /var/log/syslog* /var/log/user* /var/log/Xorg* /var/crash/*

sudo update-initramfs -u

sudo df -h

sudo du -hs /* | sort -k 2

sudo dpkg-query -Wf='${Installed-Size} ${Package}\n' | sort -n

sudo echo "" >~/.bash_history

# https://blog.desdelinux.net/pt/como-hacer-mantenimiento-script/