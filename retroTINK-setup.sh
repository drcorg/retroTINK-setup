#!/bin/bash

killall emulationstation

# Exit on error
set -o errexit
TEMPDIR=$(mktemp -d)

# Check for Root Access
Check_Root (){
    DIALOG_ROOT=${DIALOG=dialog}

    if [[ $EUID -ne 0 ]]; then
        $DIALOG_ROOT --title  "Insufficient privileges" --clear \
        --msgbox "\n\nThis script must be run as root.\n\nUsage:\n  wget https://raw.githubusercontent.com/Vykyan/retroTINK-setup/master/retroTINK-setup.sh -O - | sudo bash" 11 112
        exit 1
    fi
}

Continue_Install (){
    clear
    # Create Save Dirs
    SYSTEMS='arcade atari2600 atari5200 atari7800 atarilynx fds gamegear gb
    gba gbc mastersystem megadrive msx n64 neogeo nes ngp ngpc pce-cd pcengine
    ports/doom ports/quake psx sega32x segacd snes supergrafx virtualboy
    wonderswan wonderswancolor'

    for SYSTEM in $SYSTEMS; do
        mkdir -p /home/pi/RetroPie/save{files,states}/$SYSTEM
    done
    chown pi:pi -R /home/pi/RetroPie/save{files,states}

    # Copy systems config
    cp /etc/emulationstation/es_systems.cfg{,.retrotink}
    cp $TEMPDIR/es_systems.cfg /etc/emulationstation/

    # Copy Runcommands
    cp $TEMPDIR/opt-retropie-configs-all/runcommand-on{end,start}.sh /opt/retropie/configs/all/

    # Copy configs
    cp -Rf $TEMPDIR/opt-retropie-configs/* /opt/retropie/configs/
    chown -R pi:pi /opt/retropie/configs

    # Copy RetroTink theme
    cp -Rf $TEMPDIR/tft-retrotink /etc/emulationstation/themes/

    # Update Samba Shares
    cat << EOF >> /etc/samba/smb.conf
[SaveStates]
comment = pi
path = "/home/pi/RetroPie/savestates"
writeable = yes
guest ok = yes
create mask = 0644
directory mask = 0755
force user = pi
follow symlinks = yes
wide links = yes

[SaveFiles]
comment = pi
path = "/home/pi/RetroPie/savefiles"
writeable = yes
guest ok = yes
create mask = 0644
directory mask = 0755
force user = pi
follow symlinks = yes
wide links = yes
EOF

    cp /boot/config.txt{,.retrotink}
    cp -f $TEMPDIR/config.txt /boot/config.txt
    rm -rf $TEMPDIR
    $DIALOG --title "RetroTINK Installation Script" --clear \
            --yesno "\n\nInstallation Complete!  Please reboot your Rasbperry Pi now to use your new RetroTINK enabled RetroPie!\n\nReboot now?" 20 40
    case "$?" in
    0)
        sync;sync;reboot
        ;;
    1|255)
        exit 0
        ;;
    esac
}

Failed_Install (){
    $DIALOG --title  "Install Failed!" --clear \
    --msgbox "\n\nSee log for details..." 20 40
    clear;exit 1
}

Stopped_Install (){
    $DIALOG --title  "Install Canceled!" --clear \
    --msgbox "\n\nExiting..." 20 40
    clear;exit 1
}

Main_Program (){
    $DIALOG --title "RetroTINK Installation Script" --clear \
            --yesno "\nThis program will install the needed files & modify some settings to enable the use of the RetroTINK Raspberry Pi HAT with RetroPie (versions 4.3 and above)\n\nWARNING: This script should be run on a fresh installation of RetroPie and may not function properly or at all if changes have been made.\n\nContinue installation?" 20 40
    case "$?" in
        0)
            Continue_Install;;
        1|255)
            Stopped_Install;;
    esac
}

Check_Root
git clone https://github.com/marcteale/retroTINK-setup.git $TEMPDIR
Main_Program
rm -rf $TEMPDIR
