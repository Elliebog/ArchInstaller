#!/usr/bin/env bash
echo "--------------------------------------------------"
echo "                    YAY Setup                     "
echo "--------------------------------------------------"


echo "Installing packages from AUR"
echo "Installing yay"

cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm

PKGS=(
    'firefox'
    'github-desktop-bin'
    'sddm-nordic-theme-git'
    'visual-studio-code-bin'
    'zoom'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done
