#!/usr/bin/env bash

echo "--------------------------------------------------"
echo "                  General Setup                   "
echo "--------------------------------------------------"

echo "Set time zone: "
echo "Listing available timezones in 2 seconds" && sleep 1
echo "Listing available timezones in 1 second" && sleep 1

timedatectl list-timezones
read -p "Enter Timezone [Zone/Zubzone]: " zone
timedatectl set-timezone $zone

echo "Syncing hardware clock ..."
hwclock --systohc

echo "--------------------------------------------------"
echo "                  Network setup                   "
echo "--------------------------------------------------"

echo "Setting up Network"
# Get Networkmanager package and enable it
pacman -S networkmanager --noconfirm 
systemctl enable NetworkManager.service 

echo "--------------------------------------------------"
echo "               MAKE/COMPRESS FLAGS                "
echo "--------------------------------------------------"

nc=$(grep -c ^processor /proc/cpuinfo)
echo "Setting up MAKEFLAGS for $nc cores"

# get total memory and adjust make and Compressing flags
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi



echo "--------------------------------------------------"
echo "              Language/Localization               "
echo "--------------------------------------------------"

echo "Generating Locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=de-latin1 > /etc/vconsole.conf


# Enable parallel Downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

# Enable multilib repo
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

echo "--------------------------------------------------"
echo "                Installing System                 "
echo "--------------------------------------------------"

PKGS=(
    'mesa'
    'xorg'
    'xorg-server'
    'xorg-xinit'
    'xterm'
    'plasma-desktop'
    'alsa-plugins'
    'alsa-util'
    'ark'
    'bluez'
    'bluez-utils'
    'bluez-libs'
    'breeze'
    'breeze-gtk'
    'dolhpin'
    'gcc'
    'git'
    'jdk-openjdk'
    'konsole'
    'pulseaudio'
    'pulseaudio-bluetooth'
    'python'
    'rsync'
    'sudo'
    'wget'
    'zip'
    'terminus-font'
    'sddm'
)

for PKG in "${PKGS[@]}"; do
    echo "Installin: ${PKG}"
    pacman -S "$PKG" --noconfirm
done

echo "--------------------------------------------------"
echo "                Install Microcode                 "
echo "--------------------------------------------------"


# get processor type and install microcode
proc=$(lscpu | awk '/Vendor ID:/{print $3}')
case "$proc" in
    GenuineIntel)
        echo "Installing Intel microcode"
        pacman -S --noconfirm intel-ucode
        ;;
    AuthenticAMD)
        echo "INstalling AMD Microcode"
        pacman -S --noconfirm amd-ucode
        ;;
esac


echo "--------------------------------------------------"
echo "            Install Graphics Driver               "
echo "--------------------------------------------------"

# Install corrdect graphics driver
if lspci | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia --noconfirm
elif lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

echo "Done"

echo "--------------------------------------------------"
echo "                Setup Credentials                 "
echo "--------------------------------------------------"

# set the root password
passwd

# Load the installation config file
if ! source install.conf; then
    read -p "Enter your hostname: " hostname
    read -p "Enter your Username: " username
    echo "username=$username" >> ${HOME}/ArchInstall/install.conf
    echo "hostname=$hostname" >> ${HOME}/ArchInstall/install.conf
fi

# User Setup

echo "--------------------------------------------------"
echo "                   User Setup                     "
echo "--------------------------------------------------"

echo "Creating User"
# Setup User
useradd -m -G wheel -s /bin/bash $username
passwd $username

# Copy remaining installation files to Home directory
cp -R /root/ArchInstall /home/$username/
chown -R $username: /home/$username/ArchInstall

echo "Setting hostname"
# Set hostname
echo $hostname > /etc/hostname

echo "Setting up sudoers file"

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# No password rights for 3_user script that runs for the created user
