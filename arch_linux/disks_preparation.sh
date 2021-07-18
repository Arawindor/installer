#!/usr/bin/env bash

#### This script is customize upon my specs, change the disks and partitions as needed (eg.: from /dev/sda1 to /dev/vda1 )
#### Prior to run the script,follow the guide about the live USB setup and the Disks initial setup

# Format partitions
printf "\e[1;32mFormat partitions\e[0m"
mkfs.vfat -n "EFI System" /dev/sda1
mkfs.ext4 -L boot /dev/sda2
mkfs.ext4 -L root /dev/sda3
mkfs.ext4 -L home /dev/sda4
sleep 1s

# load kernel modules
printf "\e[1;32mLoad kernel modules\e[0m"
modprobe dm-crypt
modprobe dm-mod
sleep 1s

# encrypt the partitions
printf "\e[1;32mEncrypt the linux and home partitions\e[0m"
cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda3
cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda4
sleep 1s

# open the encrypted partitions
printf "\e[1;32mOpen the encrypted linux and home partitions and list them\e[0m"
cryptsetup open /dev/sda3 linux
cryptsetup open /dev/sda4 home
ls /dev/mapper/
sleep 3s

# Format partitions to BTRFS and create subvolumes
printf "\e[1;32mFormat partitions to BTRFS and create subvolumes\e[0m"
mkfs.btrfs -L root /dev/mapper/linux # for the root partition
mkfs.btrfs -L home /dev/mapper/home # for the home partition
sleep 1s

# Create root's subvolumes
printf "\e[1;32mCreate root's subvolumes\e[0m"
mount -t btrfs /dev/mapper/root /mnt # mount the root partition
cd /mnt # navigate to the partition
btrfs subvolumes create root /mnt # create root subvolume
btrfs subvolumes create swap # create swap subvolume
btrfs subvolumes create snapshots # create snapshots subvolume
btrfs subvolumes create var # create var subvolume
ls # to check the subvolumes
cd /
umount -R /mnt
sleep 2s

# Create home's subvolume
printf "\e[1;32mCreate home's subvolume\e[0m"
mount -t btrfs /dev/mapper/home /mnt # mount the home partition
cd /mnt # navigate to the partition
btrfs subvolumes create home /mnt # create home subvolume
ls # to check the subvolume
cd /
umount -R /mnt
sleep 2s

# Create the mount point
printf "\e[1;32mCreate the mount point and mount the subvolumes\e[0m"
mkdir -p /mnt/swap
mkdir /mnt/snapshots
mkdir /mnt/var
mkdir /mnt/home
mkdir /mnt/boot
mkdir /mnt/boot/efi
sleep 1s

# Mount the subvolumes
mount -t btrfs -o subvol=root /dev/mapper/linux /mnt # mount root subvol to /mnt
mount -t btrfs -o subvol=swap /dev/mapper/linux /mnt/swap # mount swap subvol to /mnt/swap
mount -t btrfs -o subvol=snapshots /dev/mapper/linux /mnt/snapshots # mount snapshots subvol to /mnt/snapshots
mount -t btrfs -o subvol=var /dev/mapper/linux /mnt/var # mount var subvol to /mnt/var
mount /dev/sdXN /mnt/boot # mount boot volume (eg. /dev/sda2) to /mnt/boot
mount /dev/sdXN /mnt/boot/efi # mount EFI volume (eg. /dev/sda1) to /mnt/boot/efi
sleep 1s

# Make swap file
printf "\e[1;32mMake and activate 16GB swap file\e[0m"
cd /mnt/swap
dd if=/dev/zero of=swapfile bs=1M count=16384 # create the swap file (in this example you can create a 1GB swap file, if you want 16GB swap file set count=16384)
chmod 0600 swapfile # set the security permission to swap file
swapon swapfile # activate the swap on the swapfile
cd /mnt
sleep 1s
printf "\e[1;32mDisks preparation complete\e[0m"
sleep 1s

# Install software
read -r -p "Do you want run the pacstrap, create the fstab and arch-chroot into /mnt? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  cd /mnt
  pacstrap -i /mnt base base-devel efibootmgr grub networkmanager vim linux linux-firmware linux-headers
  genfstab -U /mnt > /mnt/etc/fstab
  arch-chroot /mnt
  printf "\e[1;32mDone! Procede with pacstrap or config your Arch installation.\e[0m"
  sleep 3s
else
  printf "\e[1;32mDone! Procede with pacstrap or config your Arch installation.\e[0m"
fi
