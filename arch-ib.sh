#!/bin/bash

# Sxript para isntlar archlinux

clear

cat <<EOF 

p------------------------------------q
       Instalador archlinux ...            
______________________________________

EOF

echo "[s]im          [n]ão ... "
read -r -p "Deseja comercar a instalação? ... " INSTALAR

if [[ "$INSTALAR" == "s" ]]; then
  echo -e "01 - Configurando o teclado ..."
  read -r -p "[1] br-abnt2   [2] us-acentos  ... " TECLA
  case "$TECLA" in
    1) loadkeys br-abnt2
    ;;
    2) loadkeys us-acentos
    ;;
    *) echo "padrão"
    ;;
  esac

  echo -e "02 - Testando conexão com a internet ..."
  ping -c3 archlinux.org

  echo -e "03 - Configurando o relógio"
  timedatectl set-ntp true

  echo -e "04 - Particionando os discos do sistema ..."
  PART=$(fdisk -l | sed -n 1p | cut -d: -f2 | cut -d, -f1 | tr -d a-zA-Z" ")
  NMSD=$(fdisk -l | sed -n 1p | sed 's/.*dev//g;s/\///' | cut -d: -f1)
  # boot
  (echo n; echo 1; echo; echo +200M; echo t; echo uefi; echo w) | fdisk /dev/$NMSD
  (echo n; echo 2; echo; echo +4G; echo t; echo 2; echo swap; echo w) | fdisk /dev/$NMSD
  (echo n; echo 3; echo; echo; echo w) | fdisk /dev/$NMSD

  echo -e "05 - Formatando as partições ..."
  mkfs.fat -F32 -n BOOT /dev/"${NMSD}1"
  mkfs.ext4 /dev/"${NMSD}3"
  mkswap /dev/"${NMSD}2"

  echo -e "06 - Montando as partições ..."
  swapon /dev/"${NMSD}2"
  mount /dev/"${NMSD}3" /mnt
  mkdir /mnt/boot
  mount /dev/"${NMSD}1" /mnt/boot

  echo -e "07 - Instalar a base ..."
  pacstrap -K /mnt base #base-devel linux linux-firmware

  cp ./arch-ib-continue.sh /mnt/

  echo -e "08 - Gerando fstab ..."
  genfstab -U /mnt >> /mnt/etc/fstab

  echo -e "09 - Chroot ..."
  arch-chroot /mnt ./arch-ib-continue.sh

  echo -e "10 - Desmontando as partições ..."
  exit
  umount -Rl /mnt
  
  echo -e "11 - Remova o pendrive do computador e aperte [ENTER] ..."
  read -sn ENTER

  reboot

else 
  exit 1
fi
