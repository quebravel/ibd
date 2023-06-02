#!/bin/bash

# Sxript para isntlar archlinux
# TODO

# MOUNTPOINTS
EFI_MOUNTPOINT="/boot" # para uefi
# ROOT_MOUNTPOINT="/dev/sda1"
# BOOT_MOUNTPOINT="/dev/sda" # para bios
MOUNTPOINT="/mnt"

if [[ -f $(pwd)/shr_fncs ]]; then
	source shr_fncs
else
	echo "shr_fncs nao encontrado"
	exit 1
fi

inicio(){
clear

cat <<EOF 
++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----
--++++----++++----++++----++++----++++----++++---- Instalador archlinux --++++----++++----++++----++++----++++----++++----++++--
++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----
EOF



 echo -e "Este é o instador do archlinux base ...\n"
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

 echo "01 - Limpar o disk sda"
 echo "L) Limpar   N) Nao"
 read -r -p "Deseja limpar o disk sda? ... " limpadisco
 case "$limpadisco" in
  l|L) 
umount -Rl "${MOUNTPOINT}";
umount -Rl "$EFI_MOUNTPOINT";
# umount -Rl /mnt/boot/efi;
swapoff -a;
    # dd if=/dev/zero of=/dev/"${NOMEDISK}" bs=1M &> /dev/null
(echo d; echo d; echo d; echo w) | fdisk /dev/${NMSD} &> /dev/null
  ;;
  n|N) echo "ok"
  ;;
  *) echo default
  ;;
esac
}


rankeando_mirrors(){

  echo -e "02 - Rankeando mirrors ..."
pacman -Sy pacman-contrib
cat /etc/pacman.d/mirrorlist

  sleep 0.2
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
}

relogio(){

  echo -e "03 - Configurando o relógio"
timedatectl set-ntp true
}

particionamento(){

  echo -e "04 - Particionando os discos do sistema ..."
(echo o; echo y; echo n; echo; echo; echo +500M; echo ef00; echo w; echo Y) | gdisk /dev/"${NMSD}"
(echo n; echo; echo; echo +4G; echo 8200; echo w; echo Y) | gdisk /dev/"${NMSD}"
(echo n; echo; echo; echo; echo; echo w; echo Y) | gdisk /dev/"${NMSD}"
}

formatando(){

  echo -e "05 - Formatando as partições ..."
mkfs.fat -F32 /dev/"${NMSD}1"
mkfs.ext4 /dev/"${NMSD}3"
mkswap /dev/"${NMSD}2"
}

montando_particoes(){

  echo -e "06 - Montando as partições ..."
mkdir -p ${MOUNTPOINT}${EFI_MOUNTPOINT}
mount /dev/"${NMSD}1" ${MOUNTPOINT}${EFI_MOUNTPOINT}
swapon /dev/"${NMSD}2"
mount /dev/"${NMSD}3" ${MOUNTPOINT}
}

instalando_kernel(){

  echo -e "07 - Instalar a base ..."
pacstrap -K "${MOUNTPOINT}" base base-devel linux linux-firmware
}

gerando_fstab_uefi(){
  
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

 echo "Criar nome do Hostname [ex: archlinux]: "
read -r HOSTS

arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTS}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${HOSTS}'/' /etc/hosts"

echo "$HOSTS" >"${MOUNTPOINT}"/etc/hostname
}


senha_root(){

 echo "SENHA ROOT"
 echo -e " \033[41;1;37m Adicionando a senha do ROOT \033[0m "
 echo "Crie a senha do ROOT ..."
arch_chroot "passwd"
}

instalando_bootloader(){
 echo -e "06 - Instalando o grub ..." # libisoburn mtools
pacstrap "${MOUNTPOINT}" efibootmgr grub-efi-x86_64 dosfstools --needed --noconfirm
arch_chroot "mkdir -p ${MOUNTPOINT}${EFI_MOUNTPOINT}"
arch_chroot "mount /dev/"${NMSD}1" ${MOUNTPOINT}${EFI_MOUNTPOINT}"
arch_chroot "grub-install --target=x86_64-efi --efi-directory=${EFI_MOUNTPOINT} --bootloader-id=arch_grub --recheck"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

criando_usuario_senha(){

 echo -e "04 - Configurando usuário"
 echo -e " \033[44;1;37m Qual o nome do usuario? \033[0m "
 read -r -p ":::... " USUARIO

arch_chroot "useradd -m -G users,wheel,power,storage -s /bin/bash $USUARIO"

 echo -e " \033[46;1;37m Crie a senha do usuário \033[0m "
arch_chroot "passwd $USUARIO"
}

internet_configuracao(){

 echo -e "05 - Configurando internet ..."
SEM_FIO_DEV=$(ip link | grep wl | awk '{print $2}' | sed 's/://' | sed '1!d')

if [[ -n $SEM_FIO_DEV ]]; then
	pacstrap "${MOUNTPOINT}" iwd --needed
else
  COM_FIO_DEV=$(ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://' | sed '1!d')
	if [[ -n $COM_FIO_DEV ]]; then
		arch_chroot "systemctl enable dhcpcd@${COM_FIO_DEV}.service"
	fi
fi
}

pacotes_extras(){

 echo "5.1 - Instalando complementos importantes ..."
pacstrap "${MOUNTPOINT}" sudo dhcpcd polkit vi --noconfirm --needed
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
particionamento
formatando
montando_particoes
instalando_kernel
gerando_fstab_uefi
zona_horario
idioma_portugues
teclado_layout
nome_host
senha_root
instalando_bootloader
criando_usuario_senha
internet_configuracao
pacotes_extras
configurando_sudo
desmontando_particoes
saindo_da_instacao
