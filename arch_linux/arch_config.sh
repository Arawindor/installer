#!/usr/bin/env bash

# Use this script as soon as you arch-chroot into the brand new pacstrapped installation

# Set root password
printf "\e[1;32mSet root password\e[0m"
passwd

# Configure locale
printf "\e[1;32mConfigure locale to Rome and it_IT\e[0m"
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc
echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=it_IT.UTF-8" >> /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf
echo "LC_CTYPE=it_IT.UTF-8" >> /etc/locale.conf
echo "KEYMAP=it" >> /etc/vconsole.conf
sleep 1s

# Configure hostname and hosts
printf "\e[1;32mConfigure hostname and hosts\e[0m"
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
sleep 1s

# Configure GRUB
printf "\e[1;32mConfigure Grub\e[0m"
echo "Define your main root partition code (eg.: sda3, nvme01, vda2, ...):"
read linux_partition_code
echo "Define your main root partition label (eg.: linux, archlinux, root, ...):"
read linux_partition_label
#sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice\/dev\/sda3:linux"/g' /etc/default/grub
sed -i 's,GRUB_CMDLINE_LINUX="",GRUB_CMDLINE_LINUX="cryptdevice/dev/'"$linux_partition_code"':'"$linux_partition_label"'",g' /etc/default/grub
sleep 1s

# Configure mkinitcpio.config
printf "\e[1;32mConfigure mkinitcpio\e[0m"
sed -i 's/ filesystems keyboard fsck/ encrypt filesystems keyboard fsck/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
sleep 1s

# Install Grub
printf "\e[1;32mInstall Grub\e[0m"
echo "Define your /boot partition (eg. sda2, nvme01, vda3, ...)"
read boot_partition_code
grub-install --boot-directory /boot --efi-directory /boot/efi /dev/$boot_partition_code
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg

# Enable Network NetworkManager
printf "\e[1;32mEnable Network Manager on Systemd\e[0m"
systemctl enable --now NetworkManager.service
ping -c 3 google.com
sleep 2s

# Add new user
printf "\e[1;32mAdd new user and give him sudo permission\e[0m"
echo "Insert the new username:"
read username
useradd -m -d /home/$username $username # to create a specific user
passwd $username # to change its password
usermod -aG wheel $username # add username to wheel group (sudo)
echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username

# Install software
read -r -p "Do you want to install sddm and KDE Plasma? If not, install base sofware [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    sudo pacman -Syu plasma sddm kdednsutils vi vim tmux htop bpytop libreoffice-still\
    git wget networkmanager-openvpn neofetch powerline-fonts ttf-fira-code starship\
    barrier notepadqq joplin joplin-dektop ranger topgrade bash-completion\
    xorg-xinput rofi dmenu networkmanager-dmenu-git polybar wmctrl atom gitkraken\
    pycharm-community-edition
else
  sudo pacman -Syu vi vim tmux htop bpytop libreoffice-still\
  git wget networkmanager-openvpn neofetch powerline-fonts ttf-fira-code starship\
  barrier notepadqq joplin joplin-dektop ranger topgrade bash-completion\
  xorg-xinput rofi dmenu networkmanager-dmenu-git polybar wmctrl atom gitkraken\
  pycharm-community-edition
fi

# Process Complete
printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
