#!/bin/env bash

_sx="sudo xbps-install"

unset wm_gj video

usage(){
echo "Opção inválida!
            use:
                -p                      Programas
                -a                      Pulseaudio
                -w<bspwm|awesome>       Window Manager + Opcao
                -v<intel|amdgpu|nvidia  Video + opcao
                -n                      Navegador qutebrowser
                -b                      Remove bip
                -f                      Instala bitmap fontes e configura
                -g                      Instala o google chrome"

}

# --- PROGRAMAS ---
programas(){
    $_sx -Su && $_sx xdo xdotool exa maim xsetroot mpv feh xset xrdb xclip xsel python3-neovim python3-youtube-dl the_silver_searcher git wget ntfs-3g xorg-{minimal,fonts} rxvt-unicode urxvt-perls xf86-input-{evdev,joystick,libinput} libEGL curl alsa-utils w3m-img zathura-pdf-poppler adwaita-icon-theme pfetch htop xcursor-vanilla-dmz-aa mpd mpc ncmpcpp yad base-devel python3-devel jq vnstat nodejs go xtools cmake libX11-devel libXinerama-devel libXft-devel
    # bat
}

# --- AUDIO ---
pulse(){
    $_sx pulseaudio PAmix alsa-plugins
    sudo ln -s /etc/sv/dbus /var/service/
    sudo ln -s /etc/sv/pulseaudio /var/service/
}

# --- NAVEGADOR ---
navegador(){
#    $_sx qutebrowser
    echo "Adicionando dicionário"
    /usr/share/qutebrowser/scripts/dictcli.py install pt-BR
}

# --- REMOVER BIP ---
bip_remover(){
    echo 'blacklist pcspkr' | sudo tee /etc/modprobe.d/blacklist.conf
}

# --- CONFIGURAR FONTES ---
conf_font(){
    $_sx google-fonts-ttf
    mkdir -p ~/.local/share/fonts/
    sleep 1
    git clone https://github.com/Tecate/bitmap-fonts.git ; cd bitmap-fonts; cp -avr bitmap/ ~/.local/share/fonts/ ; cd ../ ; rm -rf bitmap-fonts ; xset fp+ ~/.local/share/fonts/bitmap ; xset fp rehash ; fc-cache -f ~/.local/share/fonts/
    sleep 1
    sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
    sudo ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
    sudo ln -s /usr/share/fontconfig/conf.avail/70-yes-bitmaps.conf /etc/fonts/conf.d/
}

chrome(){
    sh -c "$(wget -O- https://raw.githubusercontent.com/quebravel/myscripts/master/chrome-xbps-src.sh)"
    echo -e "\ngoogle-chrome [ok]"
}

while getopts ":paw:v:nbfg" o; do
    case "${o}" in
        p) programas
            ;;
        a) pulse
            ;;
        w) wm_gj=$OPTARG
            ;;
        v) video=$OPTARG
            ;;
        n) navegador
            ;;
        b) bip_remover
            ;;
        f) conf_font
            ;;
        g) chrome
            ;;
        h|?) usage
            ;;
    esac
done

# --- SE NENHUM ARGUMENTO --
if [[ $# -ge 1 ]]
then
   echo ''
else
    usage
fi

# --- WINDOW MANAGER --- [bspwm,awesome]
if [[ ! -z $wm_gj ]]
then
    $_sx $wm_gj unclutter-xfixes numlockx
    wget https://raw.githubusercontent.com/quebravel/dotfiles-conf/master/.xinitrc -P ~/
fi

if [[ bspwm == ${wm_gj} ]]
then
    $_sx polybar sxhkd
fi

# --- VIDEO --- [amdgpu,nvidia,intel]
if [[ ! -z $video ]]
then
     $_sx xf86-video-$video
fi


if [[ $video -ne "intel" || $video -ne "amdgpu" || $video -ne "nvidia" ]]
then
    echo -e "Drive de video invalido\n use intel amdgpu nvidia"
    exit 1
fi

 shift $(($OPTIND -1))
