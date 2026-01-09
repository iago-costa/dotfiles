#!/bin/bash
#Script Automatizado para atualização e limpeza.
#INICIO
clear
echo "Usando o comando apt update e full-upgrade para atualização"
sudo apt update -y
sudo apt full-upgrade -y
echo "atualização dos pacotes flatpak"
sleep 2
sudo flatpak update -y
echo "Update e Upgrade concluído!"
sleep 2
echo "Iniciando a Limpeza do Sistema com os comandos apt:"
sleep 2
sudo apt autoremove -y
sudo apt autoclean -y
sudo apt clean
echo "Limpeza concluída"
sleep 2
exit
#FIM

# https://www.vivaolinux.com.br/script/Manutencao-e-limpeza-do-Linux