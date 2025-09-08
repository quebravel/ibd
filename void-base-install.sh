#!/bin/bash

# Script para instalar o sistema base voidlinux
# Baseado e com pedaços das aulas do youtuber "terminal root" e do script famoso aui do "helmultdu"
#TODO em contrução
#ADD 
#

# ARQUETERUA DO PROCESSADOR AMD64
ARCH=x86_64
# TECLADO
KEYMAP=us

# MIRRORS
# padrão
# REPO=https://repo-default.voidlinux.org/current
# chicago
REPO=https://mirrors.servercentral.com/voidlinux/current

# MOUNTPOINTS
EFI_MOUNTPOINT="/boot/efi" # para uefi
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

# CHROOT mudar <-
# chroot "${MOUNTPOINT}"() {
# 	chroot $MOUNTPOINT "${1}"
# }
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


# -> inicio detecta bios/uefi automatico -->
particionamento_uefi(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

# FDISK
echo -en "$PROSS - PARTICIONAMENTO."
(echo o; echo n; echo p; echo 1; echo; echo +1G; echo Y; echo t; echo; echo uefi; echo a; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG
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

VAI_prepare_chroot() {
    # Mount efivars if this is an EFI system
    if [ -d /sys/firmware/efi ] ; then
        mount -t efivarfs none /sys/firmware/efi/efivars
    fi

    # Mount dev, bind, proc, etc into chroot
    mount -t proc proc "${MOUNTPOINT}/proc"
    mount --rbind /sys "${MOUNTPOINT}/sys"
    mount --rbind /dev "${MOUNTPOINT}/dev"
}

gerando_fstab(){
  xgenfstab -U "${MOUNTPOINT}" > /mnt/etc/fstab 
}

# Entering the Chroot
nome_host(){
  HOSTS="void"
  echo "$HOSTS" > "${MOUNTPOINT}"/etc/hostname
  # chroot "${MOUNTPOINT}" "sed -i '/127.0.0.1/s/$/ '${HOSTS}'/' /etc/hosts"
  # chroot "${MOUNTPOINT}" "sed -i '/::1/s/$/ '${HOSTS}'/' /etc/hosts"
}

# Installation Configuration
idioma_portugues(){
  chroot "${MOUNTPOINT}" sed -i 's/#pt_BR.U/pt_BR.U/' /etc/default/libc-locales
  chroot "${MOUNTPOINT}" sed -i 's/en_US.U/pt_BR.U/' /etc/locale.conf
  # chroot "${MOUNTPOINT}" "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
  chroot "${MOUNTPOINT}" xbps-reconfigure -f glibc-locales
  sleep 0.2
  # chroot "${MOUNTPOINT}" export LANG=pt_BR.UTF-8
  # sleep 0.2
  # export LANG=pt_BR.UTF-8
}

# Set a Root Password
senha_root(){
  echo -e "$CAC - Crie a senha do $(echo -e "\e[1;31m")ROOT$(echo -e "\e[0m")."
  if ! chroot "${MOUNTPOINT}" passwd
  then
    echo "ERROU A SENHA ROOT"
    sleep 5
    senha_root
  fi
}

# Enable services
ssh_configuracao(){

chroot "${MOUNTPOINT}"	sed -i '/Port 22/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/Protocol 2/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/HostKey \/etc\/ssh\/ssh_host_rsa_key/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/HostKey \/etc\/ssh\/ssh_host_dsa_key/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/KeyRegenerationInterval/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/ServerKeyBits/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/SyslogFacility/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/LogLevel/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/LoginGraceTime/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PermitRootLogin/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/HostbasedAuthentication no/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/StrictModes/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/RSAAuthentication/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PubkeyAuthentication/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/IgnoreRhosts/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/AllowTcpForwarding/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/AllowTcpForwarding no/d' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/X11Forwarding/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/X11Forwarding/s/no/yes/' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i -e '/\tX11Forwarding yes/d' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/X11DisplayOffset/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/X11UseLocalhost/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PrintMotd/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PrintMotd/s/yes/no/' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/PrintLastLog/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/TCPKeepAlive/s/^#//' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/the setting of/s/^/#/' /etc/ssh/sshd_config
chroot "${MOUNTPOINT}"	sed -i '/RhostsRSAAuthentication and HostbasedAuthentication/s/^/#/' /etc/ssh/sshd_config

chroot "${MOUNTPOINT}" ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
sleep 0.2
echo -e "$COK - SSH."
}

internet_configuracao(){

SEM_FIO_DEV=$(ip link | grep wl | awk '{print $2}' | sed 's/://' | sed '1!d')
COM_FIO_DEV=$(ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://' | sed '1!d')

if [[ -n $SEM_FIO_DEV ]]; then
  # XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" iwd
	# pacstrap "${MOUNTPOINT}" iwd --needed &>> $INSTLOG
	chroot "${MOUNTPOINT}" xbps-install -Sy iwd
	chroot "${MOUNTPOINT}" ln -s /etc/sv/iwd /etc/runit/runsvdir/default/

  echo "SEM FIO OK"
elif [[ -n $COM_FIO_DEV ]]; then

		chroot "${MOUNTPOINT}" ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/

 	echo "COM FIO OK"
fi

sleep 0.2

 echo -e "$COK - DISPOSITIVO DE INTERNET"
}

# usuario
criando_usuario_senha(){

 read -rep "$(echo -e $CAC) - Qual o nome do $(echo -e $LETRA)usuário$(echo -e $RESET)? -> " USUARIO

chroot "${MOUNTPOINT}" useradd -m -G users,wheel,video,audio,storage,input -s /bin/bash $USUARIO

echo -e "$CAC - Crie a senha do usuário."
if ! chroot "${MOUNTPOINT}" passwd "$USUARIO"
then
  echo "ERROU A SENHA ROOT"
  criando_usuario_senha
fi
sleep 0.2
 echo -e "$COK - USUÁRIO $USUARIO"
}

# usuario
configurando_sudo(){

# desomentando grupo de usuario wheel
chroot "${MOUNTPOINT}" sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
sleep 0.2

 echo -e "$COK - CONFIGURADO VOID E SUDO."
}

zona_horario(){

# chroot "${MOUNTPOINT}" "ln -sf /usr/share/zoneinfo/America/Belem /etc/localtime"
rm -rf "${MOUNTPOINT}"/etc/localtime
ln -s /usr/share/zoneinfo/America/Belem "${MOUNTPOINT}"/etc/localtime
# chroot "${MOUNTPOINT}" "hwclock --systohc"
# chroot "${MOUNTPOINT}" xbps-reconfigure -f glibc-locales
sleep 0.2
 echo -e "$COK - TIMEZONE LOCALIZAÇAO."
}

teclado_layout(){
    if [ "${KEYMAP}" != "us" ] ; then
        sed -i "s:\"es\":\"${KEYMAP}\":" "${MOUNTPOINT}/etc/rc.conf"
        sed -i "s:#KEYMAP:KEYMAP:" "${MOUNTPOINT}/etc/rc.conf"
    fi

}

instalando_bootloader_uefi(){
 echo -en "$PROSS - INSTALAÇAO GRUB."
sleep 0.2
#chroot "${MOUNTPOINT}" xbps-install efibootmgr grub-x86_64-efi dosfstools
XBPS_ARCH="${ARCH}" xbps-install -S -r "${MOUNTPOINT}" -R "${REPO}" efibootmgr grub-x86_64-efi dosfstools
# chroot "${MOUNTPOINT}" mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
# chroot "${MOUNTPOINT}" mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
# chroot "${MOUNTPOINT}" mount -t efivarfs none /sys/firmware/efi/efivars
chroot "${MOUNTPOINT}" grub-install --target=x86_64-efi --efi-directory=${EFI_MOUNTPOINT} --bootloader-id=void_grub --recheck
chroot "${MOUNTPOINT}" grub-mkconfig -o /boot/grub/grub.cfg
sleep 0.2
chroot "${MOUNTPOINT}" xbps-reconfigure -fa
 echo -e "$COK - GRUB UEFI." # libisoburn mtools
}

instalando_bootloader_bios(){
 echo -en "$PROSS - INSTALAÇAO GRUB."
sleep 0.2
XBPS_ARCH="${ARCH}" xbps-install -S -r "${MOUNTPOINT}" -R "${REPO}" grub
# chroot "${MOUNTPOINT}" grub-install --target=i386-pc --recheck /dev/${NMSD}
chroot "${MOUNTPOINT}" grub-install /dev/${NMSD}
chroot "${MOUNTPOINT}" grub-mkconfig -o /boot/grub/grub.cfg
sleep 0.2
chroot "${MOUNTPOINT}" xbps-reconfigure -fa
 echo -e "$COK - GRUB BIOS."
}

instalando_bootloader(){
if [[ -d /sys/firmware/efi ]]; then
 instalando_bootloader_uefi
else
 instalando_bootloader_bios
fi
}

pacotes_extras(){
XBPS_ARCH="${ARCH}" xbps-install -S -r "${MOUNTPOINT}" -R "${REPO}" dejavu-fonts-ttf xorg-fonts nerd-fonts-symbols-ttf neovim
}

nvim_simples() {
 chroot "${MOUNTPOINT}" "mkdir -p /root/.config/nvim/"
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.number = true' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.wrap = true' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.tabstop = 2' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.shiftwidth = 2' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.smartcase = true' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.ignorecase = true' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.hlsearch = false' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'vim.o.signcolumn = "yes"' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'local ok_theme = pcall(vim.cmd.colorscheme, \"retrobox\")' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'if not ok_theme then' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e '  vim.cmd.colorscheme(\"habamax\")' >> /root/.config/nvim/init.lua" 
 chroot "${MOUNTPOINT}" "echo -e 'end' >> /root/.config/nvim/init.lua" 
}

desmontando_particoes(){
sync
umount -Rl ${MOUNTPOINT}
swapoff -a
  echo -e "$COK - PARTIÇOES DESMONTADAS."
}

saindo_da_instacao(){

  echo -e "$CAC - Remova o pendrive do computador e aperte [ENTER]."
  read -r ENTER
  case "$ENTER" in
    *) reboot -f
    ;;
    c) echo exit
    ;;
    q) echo exit
    ;;
  esac
}

inicio
selecionar_dispositivo
umount_partitions
qual_boot
base_install
VAI_prepare_chroot
nome_host
idioma_portugues
senha_root
ssh_configuracao
internet_configuracao
criando_usuario_senha
configurando_sudo
zona_horario
teclado_layout
instalando_bootloader
gerando_fstab

pacotes_extras
### dns_config
nvim_simples
desmontando_particoes
saindo_da_instacao
