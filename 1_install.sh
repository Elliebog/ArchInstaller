#!/usr/bin/env bash

#----------------------------------
#   Author: Ellie Bogner
#   Date: 02/12/2021   
#----------------------------------

echo "Checking PreInstallation setup"
if [[! -f "PRE_INSTALLATION_FINISHED"]]; then
    exit
fi

echo "--------------------------------------------------"
echo "            Arch Install on Main Drive            "
echo "--------------------------------------------------"
echo "Run Pacstrap and install base system"

# Pacstrap will copy mirror list from /etc/pacman.d/mirrorlist over to /mnt/etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel linux linux-firmware nano sudo wget --noconfirm --needed
echo "Generating fstab file"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Prepare chrooting into main system"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# copy bash scripts and content of folder
cp -R $SCRIPT_DIR /mnt/root/ArchInstall

echo "--------------------------------------------------"
echo "            System ready for chroot               "
echo "--------------------------------------------------"
