#!/bin/bash

# Script para instalar o sistema base voidlinux
# Baseado e com pedaços das aulas do youtuber "terminal root" e do script famoso aui do "helmultdu"
#TODO em contrução
#ADD 
#


# MOUNTPOINTS
EFI_MOUNTPOINT="/boot" # para uefi
MOUNTPOINT="/mnt"

# NOME DO DISCO
# export NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)
LETRA="\e[1;36m"
RESET="\e[0m"

CNT="[\e[1;36mNOTA\e[0m]" #azul
COK="[\e[1;32mOK\e[0m]" #verde
CER="[\e[1;31mERRO\e[0m]" #vermelhor claro
CAT="[\e[1;37mATENCAO\e[0m]" #branco
CWR="[\e[1;35mALERTA\e[0m]" #roxo claro
CAC="[\e[1;33mACAO\e[0m]" #amarelo
INSTLOG="$HOME/install.log"
hIN_INST="&>> $INSTLOG & show_progress $!"
PROSS="[\e[1;35mEXECUTANDO\e[0m"

# show_progress() {
#     while ps | grep $1 &> /dev/null;
#     do
#         echo -n "."
#         sleep 2
#     done
#     echo -en "\e[1;32mPRONTO!\e[0m]\n"
#     sleep 2
# }

contains_element() {
	#verificar se existe um elemento em uma string
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done
}

selecionar_dispositivo() {
	devices_list=($(lsblk -d | awk '{print $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
	# PS3="$prompt1"
	echo -e "Dispositivos conectados:\n"
	lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135,259 | awk '{print $1,$4,$6,$7}' | column -t
	echo -e "\n"
	echo -e "\n$CAC - Selecione o dispositivo para o particionamento:\n"
	select device in "${devices_list[@]}"; do
		if contains_element "${device}" "${devices_list[@]}"; then
			echo $device
			export NMSD=$device
			break
		else
			echo -e "$CER - Opçao invalida"
			selecionar_dispositivo
		fi
	done
	# BOOT_MOUNTPOINT=$device
}

# ARCH-CHROOT mudar <-
arch_chroot() {
	arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
}
# DESMONTAR PARTICOES
desmontar_particoes() {
	particoes_montadas=($(lsblk | grep "${MOUNTPOINT}" | awk '{print $7}' | sort -r))
	swapoff -a &>> $INSTLOG
	for i in "${particoes_montadas[@]}"; do
		umount "$i" &>> $INSTLOG
	done
}

# [ -d /sys/firmware/efi ] && sistema_boot="UEFI" || sistema_boot="BIOS"

inicio(){
clear

cat <<EOF 
++++----++++----++++----++++----++++----++++----++++----++++----++++----++
--++++----++++----++++---- Instalador voidlinux --++++----++++----++++----
++++----++++----++++----++++----++++----++++----++++----++++----++++----++

                  Este é o meu instalador da base Void Linux 
                  pessoal  com todos as minhas  preferencias 
                  de instalaçao, fique livre para  modeficar  
                  e  utilzar como quiser.

                  O script já detecta se o sistema de boot é 
                  BIOS ou UEFI.

                  Instala e configura  o  SUDO,  VI, POLKIT,
                  LINUX-FIRMWARE         e       LINUX-DEVEL

++++----++++----++++----++++----++++----++++----++++----++++----++++----++
EOF


 echo -e "\n"
 read -rep "$(echo -e $CAC) - Deseja comerçar a instalação? - (s,n) ... " INSTALAR

case "$INSTALAR" in
  S|s) echo ""
  ;;
  N|n) exit 0
  ;;
  *) inicio
  ;;
esac

}

umount_partitions() {

#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

 read -rep "$(echo -e $CAC) - Deseja LIMPAR o disco $(echo -e $NMSD)? - (s,n) ... " LIMPADISCO
 case "$LIMPADISCO" in
  s|S) 
    echo -en "$PROSS - DESMONTAGEN DE DISCOS."
   desmontar_particoes
   umount -Rl /mnt/boot &>> $INSTLOG
   umount -Rl /mnt &>> $INSTLOG
   swapoff -a &>> $INSTLOG
   (echo d; echo 1; echo d; echo 2; echo d; echo w) | fdisk /dev/${NMSD} &>> $INSTLOG
   (echo rm 1; echo rm 2; echo rm 3; echo rm 4; echo quit) | parted /dev/${NMSD} &>> $INSTLOG & show_progress $!
   #&& dd if=/dev/zero of=/dev/"${NMSD}" bs=1M
  ;;
  n|N) echo -e "$CAT - O DISCO NAO SERÁ FORMATADO."
  ;;
  *) echo -e "$CER - VOCÊ DIGITOU A LETRA ERRADA."; umount_partitions
  ;;
esac
}
