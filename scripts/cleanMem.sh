#!/bin/bash

####################################
#	Script para health check   #
####################################

# Verificando o quanto de memória RAM está sendo utilizado
FREEMEMORY="$(free -h)"

echo $FREEMEMORY

# O trecho comentado só funcionará com o comando free -h
# Aqui, estamos extraindo apenas os números do relatório e estamos ignorando todas as letras
echo $FREEMEMORY | grep -oP "([0-9.]{2,})"
FREEMEMORYNUMBER=$(echo $FREEMEMORY | grep -oP "([0-9.]{2,})" | tr '\n' ':')
#Exibindo o tratamento de dados
echo $FREEMEMORYNUMBER | grep -oP "([0-9.]{2,})" | tr '\n' ':'
#Substituindo o . por , para ser tratado como float

#Quebrando o resultado que temos em Array pelo :
IFS=:
arr=( $FREEMEMORYNUMBER )
for key in "${!arr[@]}"; do echo "$key ${arr[$key]}"; done

echo $arr

#Tirando a porcentagem de memória livre, olhando o comando Free -h, sabemos que o segundo
#conjunto de números se refere a memórias livres
ans=$(echo "scale=0; (${arr[2]} * 100)/${arr[0]}" | tr , . | bc)
echo $ans

#Verificando se a porcentagem é menor que 25%
if [[ "$ans" -lt "25" ]]; then
    #Gerando um log com o status atual da máquina
    echo "### Free Memory ###" >freememory.txt
    echo "--------------------------------------------" >>freememory.txt
    free -h >>freememory.txt # RAM e SWAP
    echo "### Uptime ###" >uptime.txt
    echo "--------------------------------------------" >>uptime.txt
    uptime >>uptime.txt # Current Load Average
    echo "### Zombie Process ###" >zombie.txt
    echo "--------------------------------------------" >>zombie.txt
    ps aux | grep 'Z' >>zombie.txt # Processos Zumbis
    echo "### CPU Utilization ###" >cpu.txt
    echo "--------------------------------------------" >>cpu.txt
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head >>cpu.txt # CPU
    cat *.txt >allInfo.txt
    ALLINFO=$(cat allInfo.txt)
    free && sync && echo 3 >/proc/sys/vm/drop_caches && free #Limpando cache
    DATE=$(date)
    echo "Verificação efetuada em ${DATE}" >>logCheck.txt
    exit 0
else
    echo "menor"
    exit 0
fi
