#!/bin/bash

# Sxript para isntlar archlinux
#TODO finishi
#ADD 
#


# MOUNTPOINTS
EFI_MOUNTPOINT="/boot" # para uefi
MOUNTPOINT="/mnt"

# NOME DO DISCO
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

# ARCH-CHROOT
arch_chroot() {
	arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
}
# DESMONTAR PARTICOES
desmontar_particoes() {
	particoes_montadas=($(lsblk | grep "${MOUNTPOINT}" | awk '{print $7}' | sort -r))
	swapoff -a
	for i in "${particoes_montadas[@]}"; do
		umount "$i"
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

                  Instala e configura  o  SUDO,  DHCPCD,  VI
                  POLKIT,   LINUX-FIRMWARE   e   LINUX-DEVEL

++++----++++----++++----++++----++++----++++----++++----++++----++++----++
EOF


 echo -e "\n"
 echo "S) Sim          N) Não ... "
 read -r -p "Deseja comercar a instalação? ... " INSTALAR

case "$INSTALAR" in
  S|s) echo "comecando"
  ;;
  N|n) exit 0
  ;;
  *) inicio
  ;;
esac

}

umount_partitions() {

NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

 echo "01 - Limpar o sistema que possa existir no seu dico $NMSD"
 echo "L) Limpar   N) Nao"
 read -r -p "Deseja limpar o disk sda? ... " limpadisco
 case "$limpadisco" in
  l|L) 
   desmontar_particoes
   umount -Rl /mnt/boot
   umount -Rl /mnt
   swapoff -a
   (echo d; echo 1; echo d; echo 2; echo d; echo w) | fdisk /dev/${NMSD}
   (echo rm 1; echo rm 2; echo rm 3; echo quit) | parted /dev/${NMSD}
   #&& dd if=/dev/zero of=/dev/"${NMSD}" bs=1M
  ;;
  n|N) echo "ok"
  ;;
  *) echo default
  ;;
esac
}


rankeando_mirrors(){

  echo -e "02 - Rankeando mirrors ..."
pacman -Sy pacman-contrib --noconfirm
cat /etc/pacman.d/mirrorlist

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo -e "\nEspere um momento enquanto faço um rank com os 8 melhores mirrors ..."

if ! rankmirrors -n 8 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist; then
 rm /etc/pacman.d/mirrorlist && mv /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
fi

cat /etc/pacman.d/mirrorlist
}

relogio(){

  echo -e "03 - Configurando o relógio"
timedatectl set-ntp true
}

particionamento_uefi(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "04 - Particionando os discos do sistema  em UEFI ..."
# FDISK
(echo o; echo n; echo p; echo 1; echo; echo +200M; echo Y; echo t; echo; echo uefi; echo a; echo w) | fdisk /dev/"${NMSD}"
  sleep 0.2
(echo n; echo p; echo 2; echo; echo +4G; echo Y; echo t; echo 2; echo swap; echo w) | fdisk /dev/"${NMSD}"
  sleep 0.2
(echo n; echo p; echo 3; echo; echo; echo w) | fdisk /dev/"${NMSD}"
  sleep 0.2

# PARTED
# (echo mkpart "EFI" fat32 1MiB 301MiB; echo set 1 esp on; echo mkpart "swap" linux-swap 301MiB 4.3GiB; echo mkpart "root" ext4 4.3GiB 100%; echo quit) | parted /dev/"${NMSD}"
}

particionamento_bios(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "04 - Particionando os discos do sistema  em BIOS ..."

  # PARTED
(echo mkpart primary ext4 1MiB 100%; echo set 1 boot on; echo quit) | parted /dev/"${NMSD}"
}


formatando_uefi(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "05 - Formatar as partições UEFI ..."
  sleep 0.2
mkfs.vfat -F32 /dev/"${NMSD}1"
  sleep 0.2
mkfs.ext4 /dev/"${NMSD}3"
  sleep 0.2
mkswap /dev/"${NMSD}2"
}

formatando_bios(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "05 - Formatar as partições BIOS ..."
  sleep 0.2
mkfs.ext4 /dev/"${NMSD}1"
}


montando_particoes_uefi(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "06 - Montando as partições ..."
  sleep 0.2
mount /dev/"${NMSD}3" "${MOUNTPOINT}"
  sleep 0.2
mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
  sleep 0.2
mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}"
  sleep 0.2
swapon /dev/"${NMSD}2"
}

montando_particoes_bios(){
NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  echo -e "06 - Montando as partições ..."
  sleep 0.2
mount /dev/"${NMSD}1" "${MOUNTPOINT}"
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

  echo -e "07 - Instalar a base ..."
pacstrap "${MOUNTPOINT}" base base-devel linux linux-firmware
}

gerando_fstab(){
  
  echo -e "08 - Gerando fstab ..."
genfstab -t PARTUUID -p "${MOUNTPOINT}" >>"${MOUNTPOINT}"/etc/fstab
}

# ----- arch-chroot /
#
zona_horario(){

 echo -e "01 - Timezone Localização ..."
arch_chroot "ln -sf /usr/share/zoneinfo/America/Belem /etc/localtime"
arch_chroot "hwclock --systohc"
}

idioma_portugues(){

 echo -e "02 - Idioma ..."
arch_chroot "sed -i 's/#pt_BR.U/pt_BR.U/' /etc/locale.gen"
arch_chroot "locale-gen"
arch_chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
arch_chroot "export LANG=pt_BR.UTF-8"
}

teclado_layout(){
 echo -e "\n"
 echo -e "03 - Teclado do sistema ..."
 read -r -p "[1] br-abnt2   [2] us-acentos  ... " TECLAVCON
case "$TECLAVCON" in
  1) arch_chroot "echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf"
  ;;
  2) arch_chroot "echo 'KEYMAP=us-acentos' > /etc/vconsole.conf"
  ;;
  *) echo "padrão"
  ;;
esac
}

nome_host(){

 echo -e "\n"
 echo -e " \033[42;1;37m Criar nome do Hostname (ex: archlinux) \033[0m "
 read -r -p "-> " HOSTS

arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTS}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${HOSTS}'/' /etc/hosts"

echo "$HOSTS" >"${MOUNTPOINT}"/etc/hostname
}


senha_root(){

 echo -e "\n"
 echo -e " \033[41;1;37m Adicionando a senha do ROOT \033[0m "
 echo "Crie a senha do ROOT ..."
arch_chroot "passwd"
}

instalando_bootloader_uefi(){
 echo -e "06 - Instalando o grub ..." # libisoburn mtools
pacstrap "${MOUNTPOINT}" efibootmgr grub-efi-x86_64 dosfstools --needed --noconfirm
arch_chroot "mkdir -p "${MOUNTPOINT}""${EFI_MOUNTPOINT}""
arch_chroot "mount /dev/"${NMSD}1" "${MOUNTPOINT}""${EFI_MOUNTPOINT}""
arch_chroot "grub-install --target=x86_64-efi --efi-directory=${MOUNTPOINT}${EFI_MOUNTPOINT} --bootloader-id=arch_grub --recheck"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

instalando_bootloader_bios(){
pacstrap "${MOUNTPOINT}" grub --needed --noconfirm
arch_chroot "grub-install --target=i386-pc --recheck /dev/${NMSD}"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

instalando_bootloader(){
if [[ -d /sys/firmware/efi ]]; then
 instalando_bootloader_uefi
else
 instalando_bootloader_bios
fi
}

criando_usuario_senha(){

 echo -e "\n"
 echo -e "04 - Configurando usuário"
 echo -e " \033[44;1;37m Qual o nome do usuario? \033[0m "
 read -r -p "-> " USUARIO

arch_chroot "useradd -m -G users,wheel,power,storage -s /bin/bash $USUARIO"

 echo -e " \033[46;1;37m Crie a senha do usuário \033[0m "
arch_chroot "passwd $USUARIO"
}

pacotes_extras(){

 echo "5.1 - Instalando complementos importantes ..."
pacstrap "${MOUNTPOINT}" sudo dhcpcd polkit vi openssh --noconfirm --needed
}

configurando_sudo(){

 echo "5.2 - Configurando pacman e sudo ... "
# desomentando grupo de usuario wheel
arch_chroot "sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^#//' /etc/sudoers"
# ativando downloads paraleros
arch_chroot "sed -i '/ParallelDownloads/s/^#//' /etc/pacman.conf"
# adicionando cores e tema pacman
arch_chroot "sed -ie 's/#Color/Color\nILoveCandy/g' /etc/pacman.conf"
}

internet_configuracao(){

 echo -e "06 - Configurando internet ..."
SEM_FIO_DEV=$(ip link | grep wl | awk '{print $2}' | sed 's/://' | sed '1!d')
COM_FIO_DEV=$(ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://' | sed '1!d')

if [[ -n $SEM_FIO_DEV ]]; then
	pacstrap "${MOUNTPOINT}" iwd --needed
	arch_chroot "systemctl enable iwd.service"
else
	if [[ -n $COM_FIO_DEV ]]; then
		arch_chroot "systemctl enable dhcpcd@${COM_FIO_DEV}.service"
	fi
fi
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

arch_chroot "systemctl enable ssdh"
}


#
# ----- \ chroot

desmontando_particoes(){

  echo -e "11 - Desmontando as partições ..."
umount -Rl ${MOUNTPOINT}
swapoff -a
}

saindo_da_instacao(){

clear

  echo -e "12 - Remova o pendrive do computador e aperte [ENTER] ..."
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


