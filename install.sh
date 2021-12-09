#!/bin/bash

    bash 0_preinstall.sh
    bash 1_install.sh
    source /mnt/root/ArchInstall/install.conf
    arch-chroot /mnt /mnt/root/ArchInstall/2_setup.sh
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchInstall/3_user.sh
    arch-chroot /mnt /root/ArchInstall/4_post_setup.sh
