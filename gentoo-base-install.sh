#!/bin/bash

# Script para instalar o sistema base gentoolinux
# Baseado e com pedaços das aulas do youtuber terminal root e do script famoso aui do helmultdu
#TODO concertar
#FIXME
#BUG ainda bugado 


# MOUNTPOINTS
EFI_MOUNTPOINT="/boot" # para uefi
MOUNTPOINT="/mnt/gentoo"

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

# GENTOO-CHROOT
gentoo_chroot() {
	chroot $MOUNTPOINT /bin/bash -c "${1}"
}
# DESMONTAR PARTICOES
# desmontar_particoes() {
# 	particoes_montadas=($(lsblk | grep "${MOUNTPOINT}" | awk '{print $7}' | sort -r))
# 	swapoff -a ##&>> $INSTLOG
# 	for i in "${particoes_montadas[@]}"; do
# 		umount "$i" ##&>> $INSTLOG
# 	done
# }

# [ -d /sys/firmware/efi ] && sistema_boot="UEFI" || sistema_boot="BIOS"

inicio(){
clear

cat <<EOF 
++++----++++----++++----++++----++++----++++----++++----++++----++++----++
--++++----++++----++++---- Instalador gentoolinux --++++----++++----++++----
++++----++++----++++----++++----++++----++++----++++----++++----++++----++

                  Este é o meu instalador da base Gentoo Linux 
                  pessoal  com todos as minhas  preferencias 
                  de instalaçao, fique livre para  modeficar  
                  e  utilzar como quiser.

                  O script já detecta se o sistema de boot é 
                  BIOS ou UEFI.

                  Instala e configura  o  SUDO,  DHCPCD,  VI
                  POLKIT,   LINUX-FIRMWARE   e   LINUX-DEVEL

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
    echo -e "$PROSS - DESMONTAGEN DE DISCOS."
   # desmontar_particoes
   umount -Rl /mnt/boot ##&>> $INSTLOG
   umount -Rl /mnt ##&>> $INSTLOG
   swapoff -a ##&>> $INSTLOG
   (echo d; echo 1; echo d; echo 2; echo d; echo w) | fdisk /dev/${NMSD} ##&>> $INSTLOG
   (echo rm 1; echo rm 2; echo rm 3; echo rm 4; echo quit) | parted /dev/${NMSD} ##&>> $INSTLOG & show_progress $!
   #&& dd if=/dev/zero of=/dev/"${NMSD}" bs=1M
  ;;
  n|N) echo -e "$CAT - O DISCO NAO SERÁ FORMATADO."
  ;;
  *) echo -e "$CER - VOCÊ DIGITOU A LETRA ERRADA."; umount_partitions
  ;;
esac
}


relogio(){

# timedatectl set-ntp true
chronyd -q
  echo -e "$COK - RELÓGIO CONFIGURADO."
}

particionamento_uefi(){

# FDISK
# echo -e "$PROSS - PARTICIONAMENTO."
(echo o; echo n; echo p; echo 1; echo; echo +200M; echo Y; echo t; echo; echo uefi; echo a; echo w) | fdisk /dev/"${NMSD}" ##&>> $INSTLOG
  sleep 1
(echo n; echo p; echo 2; echo; echo +4G; echo Y; echo t; echo 2; echo swap; echo w) | fdisk /dev/"${NMSD}" ##&>> $INSTLOG
  sleep 1
(echo n; echo p; echo 3; echo; echo; echo w) | fdisk /dev/"${NMSD}" #&>> $INSTLOG & show_progress $!
  sleep 1

# PARTED
# (echo mkpart "EFI" fat32 1MiB 301MiB; echo set 1 esp on; echo mkpart "swap" linux-swap 301MiB 4.3GiB; echo mkpart "root" ext4 4.3GiB 100%; echo quit) | parted /dev/"${NMSD}"
  echo -e "$COK - O DISCO DO SISTEMA FOI PARTICIONADO PARA UEFI."
}

particionamento_bios(){

# echo -e "$PROSS - PARTICIONAMENTO."
  sleep 1 # swap
(echo o; echo n;echo p; echo 1; echo; echo +8G; echo t; echo swap; echo w) | fdisk /dev/"${NMSD}"
  sleep 1 # raiz com boot
(echo n; echo p; echo 2; echo; echo; echo a; echo 2; echo w) | fdisk /dev/"${NMSD}" #&>> $INSTLOG & show_progress $!
  sleep 1
  echo -e "$COK - O DISCO DO SISTEMA FOI PARTICIONADO PARA BIOS."
}


formatando_uefi(){

# echo -e "$PROSS - FORMATAÇAO."
  sleep 1
mkfs.vfat -F32 /dev/"${NMSD}1" #&>> $INSTLOG
  sleep 1
mkfs.ext4 /dev/"${NMSD}3" #&>> $INSTLOG
  sleep 1
mkswap /dev/"${NMSD}2" #&>> $INSTLOG & show_progress $!
  sleep 1
  echo -e "$COK - PARTIÇÕES FORMATADAS."
}

formatando_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

echo -e "$PROSS - FORMATAÇAO."
  sleep 1 # swap
mkswap /dev/"${NMSD}1" ##&>> $INSTLOG & show_progress $!
  sleep 1 # raiz com boot
mkfs.ext4 /dev/"${NMSD}2" ##&>> $INSTLOG & show_progress $!
  # sleep 1
# mkfs.ext4 /dev/"${NMSD}3" ##&>> $INSTLOG & show_progress $!
  sleep 1
  echo -e "$COK - PARTIÇÕES FORMATADAS."
}


# montando_particoes_uefi(){
# #NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)
#
# sleep 1
# mount /dev/"${NMSD}3" "${MOUNTPOINT}"
# sleep 1
# mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
# sleep 1
# mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
#   sleep 1
# swapon /dev/"${NMSD}2"
#   sleep 1
#   echo -e "$COK - PARTIÇOES MONTADAS."
# }

montando_particoes_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

sleep 1
mount /dev/"${NMSD}2" "${MOUNTPOINT}"
swapon /dev/"${NMSD}1"
  echo -e "$COK - PARTIÇOES MONTADAS."
}

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

tarball_stage3(){
  wget https://gentoo.c3sl.ufpr.br/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt

  sleep 1
  stage_atual=$(grep ./stage3 latest-stage3-amd64-openrc.txt | cut -d/ -f2 | cut -d" " -f1)

  sleep 1
  wget https://gentoo.c3sl.ufpr.br/releases/amd64/autobuilds/current-stage3-amd64-openrc/$stage_atual -P /mnt/gentoo

  sleep 1
  (cd /mnt/gentoo && tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner)
} 


make_configuracao(){

read -rep "$(echo -e $CAC) - Qual a sua placa de vídeo? - INTEL, AMD, NVIDA - (i,a,n) ... " PLACAVIDEO
case "$PLACAVIDEO" in
  i|I) placa_video="intel"
  ;;
  a|A) placa_video="amdgpu"
  ;;
  n|N) placa_video="nvidea"
  ;;
  *) qual_processador 
  ;;
esac

numeros_processadores=$(grep -c processor /proc/cpuinfo)

  #https://wiki.gentoo.org/wiki/Safe_CFLAGS
  numero_modelo=$(grep -m1 "model" /proc/cpuinfo | cut -d:  -f2 | tr -d ' ')
  if [[ $numero_modelo = "60" ]]; then
    cflags_make="haswell"
  fi
  if [[ $numero_modelo = "58" ]]; then
    cflags_make="ivybridge"
  fi
  if [[ $numero_modelo = "42" ]] ||  [[ $numero_modelo = "45" ]]; then
    cflags_make="sandybridge"
  fi

sed -i "s/COMMON_FLAGS=\"-O2/COMMON_FLAGS=\"-march=$cflags_make -O2/g" /mnt/gentoo/etc/portage/make.conf

sed -i '/EMERGE_DEFAULT_OPTS/d' /mnt/gentoo/etc/portage/make.conf
echo 'EMERGE_DEFAULT_OPTS="--quiet-build=y --ask --load-average=2 --autounmask-write=y --with-bdeps=y"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/FEATURES/d' /mnt/gentoo/etc/portage/make.conf
echo 'FEATURES="preserve-libs collision-protect candy"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/INPUT_DEVICES/d' /mnt/gentoo/etc/portage/make.conf
echo 'INPUT_DEVICES="evdev keyboard synaptics mouse"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/LINGUAS/d' /mnt/gentoo/etc/portage/make.conf
echo 'LINGUAS="pt_BR.UTF-8 pt_BR.ISO-8859-1 pt_BR pt-BR"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/ACCEPT_LICENSE/d' /mnt/gentoo/etc/portage/make.conf
echo 'ACCEPT_LICENSE="*"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/L10N/d' /mnt/gentoo/etc/portage/make.conf
echo 'L10N="pt-BR"' >> /mnt/gentoo/etc/portage/make.conf

sed -i '/VIDEO_CARDS/d' /mnt/gentoo/etc/portage/make.conf
echo -e "VIDEO_CARDS=\"${placa_video}\"" >> /mnt/gentoo/etc/portage/make.conf

sed -i '/MAKEOPTS/d' /mnt/gentoo/etc/portage/make.conf
echo -e "MAKEOPTS=\"-j$numeros_processadores\"" >> /mnt/gentoo/etc/portage/make.conf


if [[ -d /sys/firmware/efi ]]; then
  sed -i '/GRUB_PLATFORMS/d' /mnt/gentoo/etc/portage/make.conf
  echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
else
  echo "bios" &>> /dev/null
fi

}
selecionando_espelhos(){
  mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
  mkdir --parents /mnt/gentoo/etc/portage/repos.conf
  cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
  cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
}


montando_sistemas_de_arquivos(){
  sleep 0.3
mount --types proc /proc /mnt/gentoo/proc
  sleep 0.3
mount --rbind /sys /mnt/gentoo/sys
  sleep 0.3
mount --make-rslave /mnt/gentoo/sys
  sleep 0.3
mount --rbind /dev /mnt/gentoo/dev
  sleep 0.3
mount --make-rslave /mnt/gentoo/dev
  sleep 0.3
mount --bind /run /mnt/gentoo/run
  sleep 0.3
mount --make-slave /mnt/gentoo/run
}

montando_partição_de_boot_uefi(){

  gentoo_chroot "source /etc/profile"

if [[ -d /sys/firmware/efi ]]; then
  gentoo_chroot "mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" #&>> $INSTLOG
  gentoo_chroot "mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" #&>> $INSTLOG
fi
}

emerge_profile(){
  gentoo_chroot "emerge --sync --quiet"
  gentoo_chroot "eselect profile list"
  gentoo_chroot "eselect profile set 1"
  gentoo_chroot "emerge --ask --update --deep --newuse @world"
  gentoo_chroot "emerge app-portage/cpuid2cpuflags"
  gentoo_chroot "echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags"
  gentoo_chroot "emerge gui-apps/wl-clipboard"
  gentoo_chroot "emerge dev-python/pynvim"
}

fuso_horario(){
  gentoo_chroot "echo "America/Belem" > /etc/timezone"
  gentoo_chroot "emerge --config sys-libs/timezone-data"
  gentoo_chroot "echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen"
  gentoo_chroot "locale-gen" #&>> $INSTLOG
  gentoo_chroot "echo 'LANG="pt_BR.UTF-8"' >> /etc/env.d/02locale"
  gentoo_chroot "eselect locale list"
  gentoo_chroot "env-update && source /etc/profile"
}

kernel_configuracao(){
  gentoo_chroot "emerge --ask sys-kernel/linux-firmware"

  marca_processador=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | tr -d ' ')

  if [[ $marca_processador = "GenuineIntel" ]];then
    gentoo_chroot "sys-firmware/intel-microcode"
  fi

  gentoo_chroot "emerge gentoo-kernel"
  gentoo_chroot "emerge sys-kernel/gentoo-sources"
  gentoo_chroot "emerge sys-kernel/genkernel"
  gentoo_chroot "genkernel all"
  gentoo_chroot "genkernel --install initramfs"
}

fstab_configuracao(){

if [[ -d /sys/firmware/efi ]]; then
  gentoo_chroot "echo '/dev/sda1  /boot  ext2  defaults,noatime  0 2' >> /etc/fstab"
  gentoo_chroot "echo '/dev/sda2  none   swap  sw  0 0' >> /etc/fstab"
  gentoo_chroot "echo '/dev/sda3  /      ext4  noatime   0 1' >> /etc/fstab"
else
  gentoo_chroot "echo '/dev/sda1  none   swap sw  0 0' >> /etc/fstab"
  gentoo_chroot "echo '/dev/sda2  /      ext4 noatime   0 1'  >> /etc/fstab"
fi
}

rede_configuracao(){

gentoo_chroot "echo "gentoo" > /etc/hostname"

SEM_FIO_DEV=$(ip link | grep wl | awk '{print $2}' | sed 's/://' | sed '1!d')
COM_FIO_DEV=$(ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://' | sed '1!d')

if [[ -n $SEM_FIO_DEV ]]; then
	gentoo_chroot "emerge net-wireless/iwd" #&>> $INSTLOG
	gentoo_chroot "rc-update add iwd default" #&>> $INSTLOG
	gentoo_chroot "emerge net-wireless/iw net-wireless/wpa_supplicant"
else
	if [[ -n $COM_FIO_DEV ]]; then
	  gentoo_chroot "emerge net-misc/dhcpcd"
		gentoo_chroot "rc-update add dhcpcd default" #&>> $INSTLOG
	fi
fi
sleep 0.2
 echo -e "$COK - DISPOSITIVO DE INTERNET"
  

gentoo_chroot "sed -i '/127.0.0.1/s/$/ 'gentoo'/' /etc/hosts"
gentoo_chroot "sed -i '/::1/s/$/ 'gentoo'/' /etc/hosts"

}

sistema_log_etc(){
  gentoo_chroot "emerge app-admin/sysklogd"
  gentoo_chroot "rc-update add sysklogd default"
  gentoo_chroot "emerge sys-apps/mlocate"
  gentoo_chroot "rc-update add sshd default"
  gentoo_chroot "emerge net-misc/chrony"
  gentoo_chroot "rc-update add chronyd default"
  gentoo_chroot "emerge sys-fs/e2fsprogs sys-fs/dosfstools sys-block/io-scheduler-udev-rules"
  
}

grub_boot(){
  gentoo_chroot "emerge --ask sys-boot/grub:2"
}

instalando_bootloader_uefi(){
gentoo_chroot "mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" #&>> $INSTLOG
gentoo_chroot "mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" #&>> $INSTLOG
gentoo_chroot "grub-install --target=x86_64-efi --efi-directory=${MOUNTPOINT}${EFI_MOUNTPOINT}" #&>> $INSTLOG
gentoo_chroot "grub-mkconfig -o /boot/grub/grub.cfg" #&>> $INSTLOG & show_progress $!
}

instalando_bootloader_bios(){
 # echo -e "$PROSS - INSTALAÇAO GRUB."
sleep 0.2
gentoo_chroot "grub-install /dev/${NMSD}" #&>> $INSTLOG
gentoo_chroot "grub-mkconfig -o /boot/grub/grub.cfg" #&>> $INSTLOG & show_progress $!
 # echo -e "$COK - GRUB BIOS."
}

instalando_bootloader(){
if [[ -d /sys/firmware/efi ]]; then
 instalando_bootloader_uefi
else
 instalando_bootloader_bios
fi
}

configurar_root(){
  gentoo_chroot "passwd"
}

desmontando_finalizando(){
  gentoo_chroot "cd && umount -l /mnt/gentoo/dev{/shm,/pts,}"
  gentoo_chroot "umount /mnt/gentoo{/boot,/sys,/proc,}"
}

# -> Chamando as funções
inicio
selecionar_dispositivo
umount_partitions
relogio
qual_boot
tarball_stage3
make_configuracao
selecionando_espelhos
montando_sistemas_de_arquivos
montando_partição_de_boot_uefi
emerge_profile
fuso_horario
kernel_configuracao
fstab_configuracao
rede_configuracao
sistema_log
grub_boot
instalando_bootloader
configurar_root
desmontando_finalizando
