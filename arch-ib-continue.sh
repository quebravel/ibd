#!/bin/bash

echo -e "01 - Timezone Localização ..."
ln -sf /usr/share/zoneinfo/America/Belem /etc/localtime
hwclock --systohc

echo -e "02 - Idioma ..."
sed -i 's/#pt_BR.U/pt_BR.U/' /etc/locale.gen
locale-gen
echo LANG=pt_BR.UTF-8 > /etc/locale.conf
export LANG=pt_BR.UTF-8

echo -e "03 - Teclado do sistema ..."
read -r -p "[1] br-abnt2   [2] us-acentos  ..." TECLAVCON
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

echo -e "04 - Configurando usuário e o root ..."
echo "Qual o nome do usuário?"
read -r -p ":::... " USUARIO

useradd -m -G users,wheel,power,storage -s /bin/bash $USUARIO

echo "Senha do usuário ..."
passwd $USUARIO

echo "Senha do ROOT ..."
passwd

echo -e "05 - Configurando a rede de internet ..."
pacman -S sudo dhcpcd --noconfirm

DISPOSITIVO_01=`ip a | grep -i "2:" | sed -n 1p | cut -d: -f2 | tr -d " "`
DISPOSITIVO_02=`ip a | grep -i "3:" | sed -n 1p | cut -d: -f2 | tr -d " "`

if [[ -z $DISPOSITIVO_02 ]];then
  DISPOSITIVO_02="Não tem outro dispositivo"
else
  echo ""
fi

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

echo -e "06 - Instalando o grub ..."
pacman -S grub-efi-x86_64 efibootmgr --noconfirm
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
grub-install --target=x86_64-efi --efi-directory=/mnt/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg


