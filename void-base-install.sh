#!/bin/bash

# Script para instalar o sistema base voidlinux
# Baseado e com pedaços das aulas do youtuber "terminal root" e do script famoso aui do "helmultdu"
#TODO em contrução
#ADD 
#

# ARQUETERUA DO PROCESSADOR AMD64
ARCH=x86_64

# MIRRORS
# padrão
# REPO=https://repo-default.voidlinux.org/current
# chicago
REPO=https://mirrors.servercentral.com/voidlinux

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
#hIN_INST="&>> $INSTLOG & show_progress $!"
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
void_xchroot() {
	xchroot $MOUNTPOINT /bin/bash -c "${1}"
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
   (echo rm 1; echo rm 2; echo rm 3; echo rm 4; echo quit) | parted /dev/${NMSD} # &>> $INSTLOG & show_progress $!
   #&& dd if=/dev/zero of=/dev/"${NMSD}" bs=1M
  ;;
  n|N) echo -e "$CAT - O DISCO NAO SERÁ FORMATADO."
  ;;
  *) echo -e "$CER - VOCÊ DIGITOU A LETRA ERRADA."; umount_partitions
  ;;
esac
}


# --> não vai funcionar, acho que não precisa configurar
# relogio(){
# timedatectl set-ntp true
#   echo -e "$COK - RELÓGIO CONFIGURADO."
# }

# -> inicio detecta bios/uefi automatico -->
particionamento_uefi(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

# FDISK
echo -en "$PROSS - PARTICIONAMENTO."
(echo o; echo n; echo p; echo 1; echo; echo +500M; echo Y; echo t; echo; echo uefi; echo a; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG
  sleep 0.2
(echo n; echo p; echo 2; echo; echo +4G; echo Y; echo t; echo 2; echo swap; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG
  sleep 0.2
(echo n; echo p; echo 3; echo; echo; echo w) | fdisk /dev/"${NMSD}" # &>> $INSTLOG & show_progress $!
  sleep 0.2

# PARTED
# (echo mkpart "EFI" fat32 1MiB 301MiB; echo set 1 esp on; echo mkpart "swap" linux-swap 301MiB 4.3GiB; echo mkpart "root" ext4 4.3GiB 100%; echo quit) | parted /dev/"${NMSD}"
  echo -e "$COK - O DISCO DO SISTEMA FOI PARTICIONADO PARA UEFI."
}

particionamento_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  # PARTED
# (echo mkpart primary ext4 1MiB 100%; echo set 1 boot on; echo quit) | parted /dev/"${NMSD}"
echo -en "$PROSS - PARTICIONAMENTO."
  sleep 0.2
(echo o; echo n; echo p; echo 1; echo; echo; echo a; echo w) | fdisk /dev/"${NMSD}" # &>> $INSTLOG & show_progress $!
  sleep 0.2
  echo -e "$COK - O DISCO DO SISTEMA FOI PARTICIONADO PARA BIOS."
}


formatando_uefi(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

echo -en "$PROSS - FORMATAÇAO."
  sleep 0.2
mkfs.vfat -F32 /dev/"${NMSD}1" &>> $INSTLOG
  sleep 0.2
mkfs.ext4 /dev/"${NMSD}3" &>> $INSTLOG
  sleep 0.2
mkswap /dev/"${NMSD}2" # &>> $INSTLOG & show_progress $!
  sleep 0.2
  echo -e "$COK - PARTIÇÕES FORMATADAS."
}

formatando_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

echo -en "$PROSS - FORMATAÇAO."
  sleep 0.2
mkfs.ext4 /dev/"${NMSD}1" # &>> $INSTLOG & show_progress $!
  sleep 0.2
  echo -e "$COK - PARTIÇÕES FORMATADAS."
}


montando_particoes_uefi(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  sleep 0.2
mount /dev/"${NMSD}3" "${MOUNTPOINT}"
  sleep 0.2
mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
  sleep 0.2
mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
  sleep 0.2
swapon /dev/"${NMSD}2"
  sleep 0.2
  echo -e "$COK - PARTIÇOES MONTADAS."
}

montando_particoes_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  sleep 0.2
mount /dev/"${NMSD}1" "${MOUNTPOINT}"
  sleep 0.2
  echo -e "$COK - PARTIÇOES MONTADAS."
}

# principal boo/uefi
qual_boot(){
if [[ -d /sys/firmware/efi ]]; then
   particionamento_uefi
   formatando_uefi
   montando_particoes_uefi
else
   particionamento_bios
   formatando_bios
   montando_particoes_bios
fi
}
#<- fim detecta bios/uefi automatico

base_install(){
echo -e "$CNT - VAMOS BAIXAR O KERNEL AGORA."
  sleep 0.2
  echo -en "$PROSS - XBPS method."
  mkdir -p /mnt/var/db/xbps/keys
  cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
  XBPS_ARCH="${ARCH}" xbps-install -S -r "${MOUNTPOINT}" -R "${REPO}" base-system
 sleep 0.2
  echo -e "$COK - FINALIZADO DOWNLOAD DO KERNEL."
}

gerando_fstab(){
  xgenfstab -U "${MOUNTPOINT}" > /mnt/etc/fstab 
}


nome_host(){
  HOSTS="void"
  void_xchroot echo "$HOSTS" > /etc/hostname
  # void_xchroot "sed -i '/127.0.0.1/s/$/ '${HOSTS}'/' /etc/hosts"
  # void_xchroot "sed -i '/::1/s/$/ '${HOSTS}'/' /etc/hosts"
}

idioma_portugues(){
  "sed -i 's/#pt_BR.U/pt_BR.U/' /mnt/etc/default/libc-locales" 

  void_xchroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
  sleep 0.2
  void_xchroot "export LANG=pt_BR.UTF-8"
  sleep 0.2
  export LANG=pt_BR.UTF-8
}










inicio
selecionar_dispositivo
umount_partitions
#relogio <-- verificar se é preciso
qual_boot
base_install
gerando_fstab
nome_host
#zona_horario
idioma_portugues
#teclado_layout
#senha_root
#instalando_bootloader
#criando_usuario_senha
#pacotes_extras
#configurando_sudo
#internet_configuracao
#ssh_configuracao
## dns_config
#nvim_simples
#desmontando_particoes
#saindo_da_instacao
