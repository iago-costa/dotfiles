#!/bin/sh

#################################################################
#                                                               #
# ShellScript para limpeza de arquivos temporários do sistema   #
#                                                               #
# Autor: Phillipe Smith ( SmithuX )                             #
# Email: phillipe@archlinux.com.br                              #
#                                                               #
#################################################################

LINHAS() {
   for i in $(seq 1 50); do
      echo -n "="
   done
   echo -e "\n"
}

LIMPAR() {

   echo -e "\nOs seguintes arquivos fora encontrados: \n"
   echo -e "=============================================\n"
   sed -n 'p' $log

   if [ -s $log ]; then
      echo -e "\n============================================="
      echo -ne "\nDeseja remover os arquivos listados? [ s ou n ]:  "
      read opcao
      case $opcao in
      's')
         clear
         while [ $cont -lt $num ]; do
            comando=$cont"p"
            arquivo=$(sed -n $comando $log)
            echo -e "\n"
            rm -rfv "$arquivo"
            echo -e "\n"
            cont=$(expr $cont + 1)
         done

         LINHAS
         echo -e "\t     Operação concluída! \n"
         LINHAS
         rm -rf $log
         killall -9 $(basename $0) 2>/dev/null
         ;;

      'n')
         clear
         LINHAS
         echo -e "\t   Operação cancelada......\n"
         LINHAS
         rm -rf $log
         exit
         ;;

      *)
         clear
         echo -e "\n====> '$opcao' não é uma opção válida. <====\n\n"
         LIMPAR
         ;;
      esac
   else
      clear
      LINHAS
      echo -e "\tNenhum arquivo temporário encontrado.\n"
      LINHAS
      rm -rf $log
   fi
}

if [ $(whoami) != "root" ]; then
   echo -e """\n
==================================================
Caso você execute o aplicativo como usuário comum, 
somente será possível excluir arquivos temporários 
onde seu usuário tem permissão.
==================================================\n
"""

   echo -n "Deseja executar como root? [ s ou n ]: "
   read opt

   if [ $opt == "s" ]; then
      su root -c $(which $(basename $0))
   else
      if [ $opt == "n" ]; then
         continue
      else
         echo "Opção Inválida...."
         exit
      fi
   fi
fi

clear
echo "Procurando arquivos temporários.................."

log="/tmp/temps.log"
procurar=$(find / -iname "*~" -o -iname "*.bak" -o -iname "*.tmp" >$log 2>/dev/null)
num=$(wc -l $log | awk '{print $1}')
num=$(expr $num + 1)
cont=1

LIMPAR


# https://www.vivaolinux.com.br/script/Limpar-arquivos-temporarios