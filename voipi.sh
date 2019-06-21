#!/bin/env bash

_sx="sudo xbps-install"

$_sx -Su

$_sx xsetroot feh ranger redshift xset xrdb xsel python3-neovim bspwm sxhkd polybar git wget ntfs-3g xorg-minimal xorg-fonts xf86-video-amdgpu rxvt-unicode urxvt-perls xf86-input-{evdev,joystick,libinput} libEGL curl alsa-utils pulseaudio pulsemixer w3m-img numlockx compton xsel zathura-pdf-poppler

$_sx xcursor-vanilla-dmz-aa firefox-i18n-pt-BR firefox google-fonts-ttf


sudo echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.conf

exit 0
