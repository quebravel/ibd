#!/bin/env bash

_sx="sudo xbps-install"

$_sx -Su

$_sx scrot xsetroot mpv feh ranger redshift xset xrdb xsel python3-neovim bspwm sxhkd polybar git wget ntfs-3g xorg-minimal /
xorg-fonts xf86-video-amdgpu rxvt-unicode urxvt-perls xf86-input-{evdev,joystick,libinput} libEGL curl alsa-utils pulseaudio /
pulsemixer w3m-img numlockx xsel zathura-pdf-poppler adwaita-icon-theme

$_sx xcursor-vanilla-dmz-aa firefox-i18n-pt-BR firefox google-fonts-ttf

#$_sx unclutter

echo 'blacklist pcspkr' | sudo tee /etc/modprobe.d/blacklist.conf

sudo ln -s /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/50-user.conf /etc/fonts/conf.d/
sudo ln -s /usr/share/fontconfig/conf.avail/70-yes-bitmaps.conf /etc/fonts/conf.d/

exit 0
