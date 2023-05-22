#!/bin/bash

# Sxript para isntlar archlinux

parteUM(){

clear
cat <<EOF 
++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----
--++++----++++----++++----++++----++++----++++---- Instalador archlinux --++++----++++----++++----++++----++++----++++----++++--
++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----++++----
EOF



echo -e "Este é o instador do archlinux base ...\n"
echo "1) Sim          2) Não ... "
read -r -p "Deseja comercar a instalação? ... " INSTALAR

NOMEDISK=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

echo "01 - Limpar o disk sda"
echo "L) Limpar   N) Nao"
read -r -p "Deseja limpar o disk sda? ... " limpadisco
case "$limpadisco" in
  l|L) dd if=/dev/zero of=/dev/"${NOMEDISK}" bs=1M
  ;;
  n|N) echo "ok"
  ;;
  *) echo default
  ;;
esac

clear

  echo -e "02 - Testando conexão com a internet ..."
  ping -c1 archlinux.org

  echo -e "03 - Configurando o relógio"
  timedatectl set-ntp true

  echo -e "04 - Particionando os discos do sistema ..."
  # PART=$(fdisk -l | sed -n 1p | cut -d: -f2 | cut -d, -f1 | tr -d a-zA-Z" ")
  NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)

  # fdisk
  # (echo n; echo; echo; echo; echo +200M; echo t; echo uefi; echo w) | fdisk /dev/"${NMSD}"
  # (echo n; echo; echo; echo; echo +4G; echo t; echo; echo swap; echo w) | fdisk /dev/"${NMSD}"
  # (echo n; echo; echo; echo; echo; echo w) | fdisk /dev/"${NMSD}"

  # gdisk
  (echo o; echo y; echo n; echo; echo; echo +500M; echo ef00; echo w; echo Y) | gdisk /dev/"${NMSD}"
  (echo n; echo; echo; echo +4G; echo 8200; echo w; echo Y) | gdisk /dev/"${NMSD}"
  (echo n; echo; echo; echo; echo; echo w; echo Y) | gdisk /dev/"${NMSD}"

  echo -e "05 - Formatando as partições ..."
  mkfs.fat -F32 -n BOOT /dev/"${NMSD}1"
  mkfs.ext4 /dev/"${NMSD}3"
  mkswap /dev/"${NMSD}2"

  echo -e "06 - Montando as partições ..."
  mkdir -p /mnt/boot/efi
  mount /dev/"${NMSD}1" /mnt/boot/efi
  swapon /dev/"${NMSD}2"
  mount /dev/"${NMSD}3" /mnt

  echo -e "07 - Instalar a base ..."
  pacstrap -K /mnt base base-devel linux linux-firmware

  echo -e "08 - Gerando fstab ..."
  genfstab -U /mnt >> /mnt/etc/fstab

# copiando o script de instalação para o sistema
  cp ./arch-base-install.sh /mnt/
  chmod +x /mnt/arch-base-install.sh

sleep 1

  echo -e "09 - Chroot ..."
  arch-chroot /mnt ./"arch-base-install.sh" "-c"

  echo -e "10 - Desmontando as partições ..."
  umount -Rl /mnt
  
  echo -e "11 - Remova o pendrive do computador e aperte [ENTER] ..."
  read -r ENTER
  case "$ENTER" in
    *) reboot
    ;;
    c) exit
    ;;
    q) echo default
    ;;
  esac

  # reboot

} ### fim parteUM


parteDOIS(){

clear

echo -e "01 - Timezone Localização ..."
ln -sf /usr/share/zoneinfo/America/Belem /etc/localtime
hwclock --systohc

echo -e "02 - Idioma ..."
sed -i 's/#pt_BR.U/pt_BR.U/' /etc/locale.gen
locale-gen
echo LANG=pt_BR.UTF-8 > /etc/locale.conf
export LANG=pt_BR.UTF-8

clear

echo -e "03 - Teclado do sistema ..."
read -r -p "[1] br-abnt2   [2] us-acentos  ... " TECLAVCON
case "$TECLAVCON" in
  1) echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
  ;;
  2) echo "KEYMAP=us-acentos" > /etc/vconsole.conf
  ;;
  *) echo "padrão"
  ;;
esac

echo "archlnx" > /etc/hostname

_HOSTS="/etc/hosts\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tarchlnx.linux\tmeuhostname"
echo -e "$_HOSTS" > /etc/hosts

clear

echo "-:-:-:-:-:-:-:-:-"
echo ""
echo "Crie a senha do ROOT"
echo "Senha do ROOT ..."
passwd

clear

echo -e "06 - Instalando o grub ..."
pacman -S efibootmgr grub --noconfirm #grub-efi-x86_64 libisoburn mtools
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi #--bootloader-id=BOOT --recheck
grub-mkconfig -o /boot/grub/grub.cfg

clear

echo -e "04 - Configurando usuário"
echo ":::::::::::::::::::::::"
echo ""
echo "Qual o nome do usuário?"
read -r -p ":::... " USUARIO

useradd -m -G users,wheel,power,storage -s /bin/bash $USUARIO

echo "Crie a senha do usuário ..."
passwd $USUARIO

clear


echo -e "05 - Configurando a rede de internet ..."
pacman -S sudo dhcpcd --noconfirm


DISPOSITIVO_01=`ip a | grep -i "2:" | sed -n 1p | cut -d: -f2 | tr -d " "`
DISPOSITIVO_02=`ip a | grep -i "3:" | sed -n 1p | cut -d: -f2 | tr -d " "`

if [[ -z $DISPOSITIVO_02 ]];then
  DISPOSITIVO_02="Não tem outro dispositivo"
else
  echo ""
fi

clear

echo -e "Qual o seu dispositivo de internet?"
read -r -p "[1] $DISPOSITIVO_01    [2] $DISPOSITIVO_02 ... " DSPSTV

case "$DSPSTV" in
  1) systemctl enable dhcpcd@${DISPOSITIVO_01}.service
  ;;
  2) systemctl enable dhcpcd@${DISPOSITIVO_02}.service
  ;;
  *) echo "Não configurar"
  ;;
esac


} ### fim parteDOIS

# logando como root
parteTres(){
sed -ie s'/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL\njonatas ALL\=\(ROOT\) NOPASSWD\: \/usr\/bin\/systemctl poweroff\,\/usr\/bin\/systemctl halt\,\/usr\/bin\/systemctl reboot/'g /etc/sudoers


# mirrorlist
urlbrasil="https://archlinux.org/mirrorlist/?country=BR&protocol=http&protocol=https&ip_version=4"
curl $urlbrasil -o mirrorlist.txt
sed -i s'/#Server/Server/'g ./mirrorlist.txt
mv /etc/pacman.d/mirrorlist /etc/pacman.d/bkp.mirrorlist
mv ./mirrorlist.txt /etc/pacman.d/mirrorlist
}

case "$1" in
  -i) parteUM
  ;;
  -c) parteDOIS
  ;;
  -u) parteTres
  ;;
  *|-h|--help) echo -e "Ajuda:\n\t-i\t\tInstalação da base com pacstrap.\n\t-c\t\tContinuação da instalação com arch-chroot."
  ;;
esac
