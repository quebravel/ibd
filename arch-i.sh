#!/bin/bash

_so="sudo pacman -S"
_s="sudo"

programas(){
$_so xdo mtools xdotool exa maim mpv feh xclip xsel python-pynvim yt-dlp the_silver_searcher git wget ntfs-3g xorg-{xsetroot,xset,xrdb,fonts} xf86-input-{evdev,libinput} curl alsa-utils zathura-pdf-poppler adwaita-icon-theme bpytop xcursor-vanilla-dmz-aa base-devel nodejs go cmake libxinerama libxft python-pip sxiv alacritty xdg-user-dirs ffmpeg pulseaudio
}

zshconfig(){
$_so zsh zsh-completions 
}

fontes(){
# fonts
$_so ttf-dejavu noto-fonts-emoji gnu-free-fonts
}

drive_video(){
# drive video
$_so xorg-{server,xinit} xf86-video-amdgpu amdvlk
echo "amdgpu configurado"
}

navegador(){
# navegador
echo "Navegador"
$_so qutebrowser
echo "Adicionando dicionário"
/usr/share/qutebrowser/scripts/dictcli.py install pt-BR
}

windownmanager(){
# wm
$_so bspwm sxhkd polybar
}

github_config(){
# dotfiles
git clone https://github.com/quebravel/dotfiles-conf ~/dotfiles-conf
cp -r ~/dotfiles-conf/.config ~/
}

configuracoes(){
# pastas padrao
xdg-user-dirs-update
# processador 
$_s sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j4\"/g" /etc/makepkg.conf
#lscpu | grep '^CPU(s):' | cut -d ' ' -f29
lscpu | grep '^CPU(s):'
echo "copilador configurado para [4] processadores"
}

temas(){
# gruvbox tema
mkdir -p ~/themes ~/icons
git clone https://github.com/jmattheis/gruvbox-dark-gtk ~/.themes/gruvbox-dark-gtk
git clone https://github.com/jmattheis/gruvbox-dark-icons-gtk ~/.icons/gruvbox-dark-icons-gtk
}

autoscript_git(){
# AUTO SCRIPTS sh -c "$()  -O-"

# ok ohmyzsh
 sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# dmenu2
 sh -c "$(wget -O- https://raw.githubusercontent.com/quebravel/myscripts/master/script_dmenu2.sh)"

# zsh alias, autopair
 sh -c "$(wget -O- https://raw.githubusercontent.com/quebravel/myscripts/master/script_zsh_alias.sh)"

# yay
 sh -c "$(wget -O- https://raw.githubusercontent.com/quebravel/myscripts/master/script_yay.sh)"

}

programas
zshconfig
fontes
drive_video
navegador
windownmanager
github_config
configuracoes
temas
autoscript_git
