#!/bin/sh

# Script para atualizar e limpar cache de pacotes antigos
# por Ricardo da Silva Lisboa
#
# v4  * Detecção de distros
#     * Detecção de flatpaks e snaps
#     * Reformulação para usar POSIX sh
#     * Suporte a AUR helpers
#
# por goll72

clear

# O script precisa ser rodado como root
[ $(id -u) -ne 0 ] && {
    echo "Esse script deve ser executado como root!"
    exit
}

# Obter ID da distro
. /etc/os-release

# Negrito
B=$(tput bold)
N=$(tput sgr0)

case "$ID $ID_LIKE" in
*arch | *artix*)
    printf "%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    pacman -Syu --noconfirm

    # Atualizar pacotes do AUR
    if pacman -Q paru >/dev/null 2>&1; then
        printf "\n%s* Atualizando o AUR...%s\n\n" "$B" "$N"
        sudo -H -u \#1000 paru -a -Syu --noconfirm
    elif pacman -Q yay >/dev/null 2>&1; then
        printf "\n%s* Atualizando o AUR...%s\n\n" "$B" "$N"
        sudo -H -u \#1000 yay -a -Syu --noconfirm
    elif pacman -Q pikaur >/dev/null 2>&1; then
        printf "\n%s* Atualizando o AUR...%s\n\n" "$B" "$N"
        sudo -H -u \#1000 pikaur -a -Syu --noconfirm
    fi

    # Checar se flatpak está instalado, se sim, atualizar
    pacman -Q flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Checar se snapd está instalado, se sim, atualizar
    pacman -Q snapd >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando snaps...%s\n\n" "$B" "$N"
        snap refresh
    }

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    pacman -Rsn $(pacman -Qdtq) --noconfirm 2>/dev/null
    pacman -Scc --noconfirm

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*debian* | *ubuntu*)
    printf "%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    apt update -y
    apt full-upgrade -y

    # Checar se flatpak está instalado, se sim, atualizar
    dpkg -s flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Checar se snapd está instalado, se sim, atualizar
    dpkg -s snapd >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando snaps...%s\n\n" "$B" "$N"
        snap refresh
    }

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    apt purge --autoremove -y
    apt autoclean -y
    apt clean

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*sles* | *opensuse*)
    printf "%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    zypper dup -y

    # Checar se flatpak está instalado, se sim, atualizar
    zypper search --installed-only flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Checar se snapd está instalado, se sim, atualizar
    zypper search --installed-only snapd >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando snaps...%s\n\n" "$B" "$N"
        snap refresh
    }

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    zypper rm $(zypper packages --unneeded) -y
    zypper clean -y

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*fedora* | *centos*)
    printf "\n%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    dnf distro-sync

    # Checar se flatpak está instalado, se sim, atualizar
    dnf list installed flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Checar se snapd está instalado, se sim, atualizar
    dnf list installed snapd >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando snaps...\n\n" "$B" "$N"
        snap refresh
    }

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    dnf autoremove
    dnf clean all

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*gentoo*)
    printf "\n%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    emerge -auDN --keep-going @world

    # Checar se flatpak está instalado, se sim, atualizar
    equery list flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Checar se snapd está instalado, se sim, atualizar
    equery list snapd >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    emerge -a --depclean
    emerge -a --clean
    eclean distfiles

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*alpine*)
    printf "\n%s* Atualizando o sistema...%s\n\n" "$B" "$N"
    apk -U upgrade

    # Checar se flatpak está instalado, se sim, atualizar
    apk -e info flatpak >/dev/null 2>&1 && {
        printf "\n  %s- Atualizando flatpaks...%s\n\n" "$B" "$N"
        flatpack update -y
    }

    # Não há snapd nos repositórios do Alpine.

    printf "\n%s* Atualizações concluídas!%s\n" "$B" "$N"

    # Limpar cache de pacotes
    printf "\n%s* Iniciando limpeza de pacotes...%s\n" "$B" "$N"

    apk cache clean

    printf "\n%s* Limpeza do cache concluída!%s\n" "$B" "$N"
    ;;

*) printf 'Distribuição não suportada: %s%s%s!\n' "$B" "$ID" "$N" ;;
esac

# Arquivo desktop
# Salve em /usr/share/applications ou ~/.local/share/applications
# com a extensão .desktop (preencha o local do script e remova os #s)
############################################
#[Desktop Entry]
#Name=Atualizar o sistema
#GenericName=Script para atualizar o sistema
#Comment=Atualizar o sistema, remover caches
#Exec=<LOCAL DO SCRIPT>
#Terminal=true
#Type=Application
############################################

# https://www.vivaolinux.com.br/script/Manutencao-e-limpeza-do-Linux