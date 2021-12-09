#!/usr/bin/env bash

#----------------------------------
#   Author: Ellie Bogner
#   Date: 02/12/2021   
#----------------------------------

source ./select_dialog

echo "--------------------------------------------------"
echo "               Starting Setup"
echo "--------------------------------------------------"

if [[ -f "PRE_INSTALL_FINISHED"]]; then
    exit
fi

# General
# Update the system clock
timedatectl set-ntp true

echo "--------------------------------------------------"
echo "          Parallel Download and Mirrors           "
echo "--------------------------------------------------"


# Setup Parallel Download
# Install pacman-contrib package for pacman tools
pacman -S --noconfirm pacman-contrib
# Uncomment #ParallelDownloads = 5
sed -i 's/^#Parallel/Parallel/' /etc/pacman.conf

# Pacman Mirrors Setup
pacman -S reflector rsync --noconfirm
# Create Backup of Pacman mirrorlist
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# get the country code
iso=$(curl -4 ifconfig.co/country-iso)
echo "Country for Mirros: $iso"
# Count the mirrors available in this country
num_mirrors=$(reflector -c $iso | awk '/Server =*/' | wc -l)
echo "There are $num_mirrors mirrors for this country"

# Ask the user for detail of mirrorlist setup
echo "Would you like to run reflector to pick the best mirrors ? (This will take some time but will ensure you have the best possible mirrorlist setup)"
while true; do
    read -p "Would you like to run reflector to generate the mirrorlist based on speed? [Y/N]" yn
    case $yn in
        [Yy]* ) 
            reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "--------------------------------------------------"
echo "                  Disk setup                      "
echo "--------------------------------------------------"

#Install packages needed for disk management
pacman -S --noconfirm gptfdisk

# Get the disk to install the system on
echo "Enter the disk to work on: (e.g. /dev/sda)"
options=($(lsblk -o "NAME" | grep -v -e - -e NAME))
device_idx=$(select_opt ${options[@]})
disk=${options[device_idx]}

echo "Wiping disk"
# Format the disk
sgdisk -Z $disk #zap everything on disk (GPT/MBR structure is destroyed)
sgdisk -a 2048 -o $disk # Create new GPT structure with 2048 alignment

if [[ ! -d "/sys/firmware/efi/efivars" ]]; then
    echo "BIOS boot mode detected. If this is not the right boot mode, refer to your motherboards manual"
    echo "If BIOS is the right BOOT mode please partition the disks for yourself using cfdisk/fdisk/gparted etc... and mount the partitions"
    echo "When you are done setting up the partitions and mounting please set the content of PRE_INSTALL_FINISHED to true"
else
    echo "Creating Partitions"
    # creating partitions 
    sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFI' $disk # EFI System partition
    sgdisk -n 2::+8G --typecode=2:8200 --change-name=2:'SWAP' $disk # Swap partition 8GB
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' $disk # Root Partition
    # formatting partitions
    mkfs.vfat -F 32 /dev/${disk}1 # formate EFI system partition
    mkswap /dev/${disk}2 # make swap
    mkfs.ext4 /dev/${disk}3 # format root partition

    echo "Mounting partitions"
    #mount partitions
    #create mount points
    mkdir /mnt
    mkdir -p /mnt/boot/efi
    # mount partitions
    mount /dev/${disk}3 /mnt # Root mount
    mount /dev/${disk}1 /mnt/boot/efi # efi mount
    swapon /dev/${disk}2 # turn on swap
fi
echo "1" > PRE_INSTALL_FINISHED

echo "If you wish to setup BTRFS follow the setup and set it up manually afterwards, because it is not yet supported"
echo "if you want this feature -> Create an issue on https://github.com/Elliebog/ArchInstall"