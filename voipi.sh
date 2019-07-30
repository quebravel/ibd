#!/bin/env bash

_sx="sudo xbps-install"

$_sx -Suy

# --- PROGRAMAS ---
$_sx -y scrot xsetroot mpv feh ranger redshift xset xrdb xsel python3-neovim git wget ntfs-3g xorg-minimal xorg-fonts rxvt-unicode urxvt-perls xf86-input-{evdev,joystick,libinput} libEGL curl alsa-utils w3m-img numlockx zathura-pdf-poppler adwaita-icon-theme neofetch htop

# --- AUDIO ---
#$_sx pulseaudio pamixer

# --- VIDEO ---
#$_sx xf86-video-amdgpu
#$_sx xf86-video-intel
#$_sx xf86-video-nvidia

# --- WINDOW MANAGER ---
#$_sx bspwm sxhkd polybar unclutter
#$_sx awesome unclutter

# --- NAVEGADOR ---
$_sx xcursor-vanilla-dmz-aa
#$_sx firefox-i18n-pt-BR firefox
#$_sx qutebrowser

# --- REMOVER BIP ---
echo 'blacklist pcspkr' | sudo tee /etc/modprobe.d/blacklist.conf

# --- CONFIGURAR FONTES ---

$_sx google-fonts-ttf
sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/70-yes-bitmaps.conf /etc/fonts/conf.d/

exit 0
