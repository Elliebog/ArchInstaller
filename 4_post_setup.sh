#!/usr/bin/env bash
echo "--------------------------------------------------"
echo "                  Setup Services                  "
echo "--------------------------------------------------"

echo "Enabling sddm"
systemctl enable sddm.service
echo "Enabling other services"
# stop dhcpcd
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service

systemctl enable NetworkManager.service
systemctl enable bluetooth

echo "--------------------------------------------------"
echo "                   Clean Setup                    "
echo "--------------------------------------------------"

echo "Finalizing sudoers file"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo "--------------------------------------------------"
echo "                FINISH GRUB SETUP                 "
echo "--------------------------------------------------"

pacman -S --noconfirm grub efibootmgr

if [[ -d "/sys/firmware/efi/efivars"]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else 
    echo "Install grub by running |grub-install --target=i386-pc /dev/sdX|"
fi


echo "Installation finished please reboot or continue setting up manually"