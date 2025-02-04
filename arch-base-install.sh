#!/bin/bash

# Script para instalar o sistema base archlinux
# Baseado e com pedaços das aulas do youtuber terminal root e do script famoso aui do helmultdu
#TODO finishi
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
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "\e[1;32mPRONTO!\e[0m]\n"
    sleep 2
}

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

# ARCH-CHROOT
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
--++++----++++----++++---- Instalador archlinux --++++----++++----++++----
++++----++++----++++----++++----++++----++++----++++----++++----++++----++

                  Este é o meu instalador da base Arch Linux 
                  pessoal  com todos as minhas  preferencias 
                  de instalaçao, fique livre para  modeficar  
                  e  utilzar como quiser.

                  O script já detecta se o sistema de boot é 
                  BIOS ou UEFI.

                  Instala e configura  o  SUDO,  VI, POLKIT,
                  NETWORKMANAGER      LINUX-FIRMWARE      e   
		  LINUX-DEVEL

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


rankeando_mirrors(){

  echo -e "$CNT - RANKEANDO MIRRORS"
  pacman -Sy pacman-contrib --noconfirm --needed &>> $INSTLOG
  # cat /etc/pacman.d/mirrorlist
if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

  echo -e "\n $CNT - ESPERE UM MOMENTO ENQUANTO FAÇO UM RANK COM OS 8 MELHORES MIRRORS."

  echo -en "$PROSS] - RANQUEAMENTO."
if ! rankmirrors -n 8 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist; then
   rm /etc/pacman.d/mirrorlist && mv /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
fi
  # cat /etc/pacman.d/mirrorlist
  tail -n 10 /etc/pacman.d/mirrorlist | head -n 1
  echo -e "$COK - MIRROS RANQUEADAS."
else
  echo -e "$CAT - MIRROS JÁ FORAM RANQUEADOS ANTES."
  sleep 1
fi
}

relogio(){

timedatectl set-ntp true
  echo -e "$COK - RELÓGIO CONFIGURADO."
}

particionamento_uefi(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

# FDISK
echo -en "$PROSS - PARTICIONAMENTO."
(echo o; echo n; echo p; echo 1; echo; echo +500M; echo Y; echo t; echo; echo uefi; echo a; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG
  sleep 0.2
(echo n; echo p; echo 2; echo; echo +4G; echo Y; echo t; echo 2; echo swap; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG
  sleep 0.2
(echo n; echo p; echo 3; echo; echo; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG & show_progress $!
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
(echo o; echo n; echo p; echo 1; echo; echo; echo a; echo w) | fdisk /dev/"${NMSD}" &>> $INSTLOG & show_progress $!
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
mkswap /dev/"${NMSD}2" &>> $INSTLOG & show_progress $!
  sleep 0.2
  echo -e "$COK - PARTIÇÕES FORMATADAS."
}

formatando_bios(){
#NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

echo -en "$PROSS - FORMATAÇAO."
  sleep 0.2
mkfs.ext4 /dev/"${NMSD}1" &>> $INSTLOG & show_progress $!
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

instalando_kernel(){
echo -e "$CNT - VAMOS BAIXAR O KERNEL AGORA."
  sleep 0.2
  echo -en "$PROSS - PACSTRAP."
pacstrap "${MOUNTPOINT}" base base-devel linux linux-firmware &>> $INSTLOG & show_progress $!
 sleep 0.2
  echo -e "$COK - FINALIZADO DOWNLOAD DO KERNEL."
}

gerando_fstab(){
  
genfstab -t PARTUUID -p "${MOUNTPOINT}" >>"${MOUNTPOINT}"/etc/fstab
 sleep 0.2
  echo -e "$COK - FSTAB."
}

# ----- arch-chroot /
#
zona_horario(){

arch_chroot "ln -sf /usr/share/zoneinfo/America/Belem /etc/localtime"
arch_chroot "hwclock --systohc"
sleep 0.2
 echo -e "$COK - TIMEZONE LOCALIZAÇAO."
}

idioma_portugues(){

arch_chroot "sed -i 's/#pt_BR.U/pt_BR.U/' /etc/locale.gen"
sleep 0.2
arch_chroot "locale-gen" &>> $INSTLOG
sleep 0.2
arch_chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
sleep 0.2
arch_chroot "export LANG=pt_BR.UTF-8"
sleep 0.2
export LANG=pt_BR.UTF-8
sleep 0.2
 echo -e "$COK - IDIOMA."
}

teclado_layout(){
 read -rep "$(echo -e $CAC) - Teclado do sistema $(echo -e $LETRA)B$(echo -e $RESET)R-ABNT2 ou $(echo -e $LETRA)U$(echo -e $RESET)S-ACENTOS (b,u) ... " TECLAVCON
case "$TECLAVCON" in
  b|B) arch_chroot "echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf"
  ;;
  u|U) arch_chroot "echo 'KEYMAP=us-acentos' > /etc/vconsole.conf"
  ;;
  *) echo -e "$CER - VOCE DIGITOU A LETRA ERRADA."; teclado_layout
  ;;
esac
}

nome_host(){

 read -rep "$(echo -e $CAC) - Criar o nome do Hostname (ex: $(echo -e $LETRA)archlinux$(echo -e $RESET)) -> " HOSTS

arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTS}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${HOSTS}'/' /etc/hosts"

echo "$HOSTS" >"${MOUNTPOINT}"/etc/hostname
echo -e "$COK - HOSTS."
}


senha_root(){

  echo -e "$CAC - Crie a senha do $(echo -e "\e[1;31m")ROOT$(echo -e "\e[0m")."
  if ! arch_chroot "passwd"
  then
    echo "ERROU A SENHA ROOT"
    senha_root
  fi
}

instalando_bootloader_uefi(){
 echo -en "$PROSS - INSTALAÇAO GRUB."
sleep 0.2
pacstrap "${MOUNTPOINT}" efibootmgr grub-efi-x86_64 dosfstools --needed --noconfirm &>> $INSTLOG
arch_chroot "mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" &>> $INSTLOG
arch_chroot "mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"" &>> $INSTLOG
arch_chroot "grub-install --target=x86_64-efi --efi-directory=${MOUNTPOINT}${EFI_MOUNTPOINT} --bootloader-id=arch_grub --recheck" &>> $INSTLOG
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" &>> $INSTLOG & show_progress $!
sleep 0.2
 echo -e "$COK - GRUB UEFI." # libisoburn mtools
}

instalando_bootloader_bios(){
 echo -en "$PROSS - INSTALAÇAO GRUB."
sleep 0.2
pacstrap "${MOUNTPOINT}" grub --needed --noconfirm &>> $INSTLOG
arch_chroot "grub-install --target=i386-pc --recheck /dev/${NMSD}" &>> $INSTLOG
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" &>> $INSTLOG & show_progress $!
sleep 0.2
 echo -e "$COK - GRUB BIOS."
}

instalando_bootloader(){
if [[ -d /sys/firmware/efi ]]; then
 instalando_bootloader_uefi
else
 instalando_bootloader_bios
fi
}

criando_usuario_senha(){

 read -rep "$(echo -e $CAC) - Qual o nome do $(echo -e $LETRA)usuário$(echo -e $RESET)? -> " USUARIO

arch_chroot "useradd -m -G users,wheel,power,storage,input -s /bin/bash $USUARIO"

echo -e "$CAC - Crie a senha do usuário."
if ! arch_chroot "passwd $USUARIO"
then
  echo "ERROU A SENHA ROOT"
  criando_usuario_senha
fi
sleep 0.2
 echo -e "$COK - USUÁRIO $USUARIO"
}

pacotes_extras(){
echo -en "$PROSS - INSTALAÇAO DE PACOTES EXTRAS."
pacstrap "${MOUNTPOINT}" sudo dhcpcd polkit vi openssh --noconfirm --needed &>> $INSTLOG & show_progress $!
 echo -e "$CNT - COMPLEMENTOS IMPORTANTES INSTALADOS."
}

configurando_sudo(){

# desomentando grupo de usuario wheel
arch_chroot "sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^#//' /etc/sudoers"
# ativando downloads paraleros
arch_chroot "sed -i '/ParallelDownloads/s/^#//' /etc/pacman.conf"
# adicionando cores e tema pacman
arch_chroot "sed -ie 's/#Color/Color\nILoveCandy/g' /etc/pacman.conf"
sleep 0.2
 echo -e "$COK - CONFIGURADO PACMAN E SUDO."
}

internet_configuracao(){

SEM_FIO_DEV=$(ip link | grep wl | awk '{print $2}' | sed 's/://' | sed '1!d')
COM_FIO_DEV=$(ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://' | sed '1!d')

if [[ -n $SEM_FIO_DEV ]]; then
	pacstrap "${MOUNTPOINT}" iwd --needed &>> $INSTLOG
	arch_chroot "systemctl enable iwd.service" &>> $INSTLOG
	arch_chroot "systemctl enable dhcpcd" &>> $INSTLOG
  	arch_chroot "echo EnableNetworkConfiguration=true > /etc/iwd/main.conf" &>> $INSTLOG
else
	if [[ -n $COM_FIO_DEV ]]; then
		arch_chroot "systemctl enable dhcpcd@${COM_FIO_DEV}.service" &>> $INSTLOG
	fi
fi
sleep 0.2
 echo -e "$COK - DISPOSITIVO DE INTERNET"
}

ssh_configuracao(){

arch_chroot	"sed -i '/Port 22/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/Protocol 2/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/HostKey \/etc\/ssh\/ssh_host_rsa_key/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/HostKey \/etc\/ssh\/ssh_host_dsa_key/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/KeyRegenerationInterval/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/ServerKeyBits/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/SyslogFacility/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/LogLevel/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/LoginGraceTime/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PermitRootLogin/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/HostbasedAuthentication no/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/StrictModes/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/RSAAuthentication/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PubkeyAuthentication/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/IgnoreRhosts/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/AllowTcpForwarding/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/AllowTcpForwarding no/d' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/X11Forwarding/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/X11Forwarding/s/no/yes/' /etc/ssh/sshd_config"
arch_chroot	"sed -i -e '/\tX11Forwarding yes/d' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/X11DisplayOffset/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/X11UseLocalhost/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PrintMotd/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PrintMotd/s/yes/no/' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/PrintLastLog/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/TCPKeepAlive/s/^#//' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/the setting of/s/^/#/' /etc/ssh/sshd_config"
arch_chroot	"sed -i '/RhostsRSAAuthentication and HostbasedAuthentication/s/^/#/' /etc/ssh/sshd_config"

arch_chroot "systemctl enable sshd"
sleep 0.2
echo -e "$COK - SSH."
}


#
# ----- \ chroot

desmontando_particoes(){

umount -Rl ${MOUNTPOINT} &>> $INSTLOG
swapoff -a &>> $INSTLOG
  echo -e "$COK - PARTIÇOES DESMONTADAS."
}

saindo_da_instacao(){

  echo -e "$CAC - Remova o pendrive do computador e aperte [ENTER]."
  read -r ENTER
  case "$ENTER" in
    *) reboot
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
rankeando_mirrors
relogio
qual_boot
instalando_kernel
gerando_fstab
zona_horario
idioma_portugues
teclado_layout
nome_host
senha_root
instalando_bootloader
criando_usuario_senha
pacotes_extras
configurando_sudo
internet_configuracao
ssh_configuracao
desmontando_particoes
saindo_da_instacao


