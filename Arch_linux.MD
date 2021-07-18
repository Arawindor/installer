# Install Arch with full disk encryption (BTRFS) and separated encrypted home partition

This guide is based on Youtube Sheridan Computers' video "How to install Arch Linux with full disk encryption (BTRFS) and KDE Plasma Desktop Environment" (https://www.youtube.com/watch?v=hJRfMgpke3E)



### Disclaimer
This guide is designed to achive a single boot Arch linux distribution and is not suitable for dual boot configuration (eg.: Windows and Linux)

## Disk partition structure
Structure:
Disk partition structure:
- linux volume (encrypted) with subvolumes:
	- @ (root)
	- @var
	- @swap
	- @snapshots
- home volume (encrypted) with subvolume:
	- @home
- boot
- boot/efi

## Installation procedure

### Live usb setup
Set keyboard layout
```sh
loadkeys it
```
Check internet connection (ethernet connection preferred)
```sh
ping 8.8.8.8   
ping google.com
```
Set daytime
```sh
timedatectl set ntp true
```
List all disks and partitons installed
```sh
lsblk
```
### Disks initial setup
```sh
fdisk /dev/sdX
m #make partition
g #create empty GPT partition
w #write partition on disk
```
Create partitions
```sh
cfdisk
```
1. Create EFI partition
	- select `New`
	- select the size `256M` (eg.: 256 MB)
	- select `EFI` in `Type`
8. create Boot partition
	- select `New`
	- select the size `512M` (eg.: 512 MB)
	- leave `Linux` in `Type`
9. create Linux partition
	- select `New`  
	- select the size `120G` (eg.: 120 GB)
	- leave `Linux` in `Type`
10. create Home partition
	- select `New`
	- select the size `120G` (eg.: 120 GB)
	- leave `Linux` in `Type`
11. write the partitions into the disk
	- select `Write`
	- confirm with `yes`
	- select `Quit` to quit cfdisk

#### Format partitions
```sh
mkfs.vfat -n "EFI System" /dev/sdXN # where XN is the EFI partition (eg. /dev/sda1)
mkfs.ext4 -L boot /dev/sdXN # where XN is the Boot partition (eg. /dev/sda2)
mkfs.ext4 -L root /dev/sdXN # where XN is the root partition (eg. /dev/sda3)
mkfs.ext4 -L home /dev/sdXN # where XN is the home partition (eg. /dev/sda4)
```
Load the encryption modules
```
modprobe dm-crypt
modprobe dm-mod
```
Configure the encryption
```sh
cryptsetup luksFormat -v -s 512 -h sha512 /dev/sdXN # where XN is the root partition (eg. /dev/sda3) and insert the ecnryption desired password
cryptsetup luksFormat -v -s 512 -h sha512 /dev/sdXN # where XN is the home partition (eg. /dev/sda4) and insert the ecnryption desired password
```
Open encrypted partition
```sh
cryptsetup open /dev/sdXN label # where XN is the root partition (eg. /dev/sda3) and the desired label (eg. linux) and enter the password
cryptsetup open /dev/sdXN label # where XN is the home partition (eg. /dev/sda4) and the desired label (eg. home) and enter the password
```
Check if the encrypted partition are opened
```sh
ls /dev/mapper/
```
#### Format with BTRFS the opened partitions and create volumes
```sh
mkfs.btrfs -L root /dev/mapper/linux # for the root partition
mkfs.btrfs -L home /dev/mapper/home # for the home partition
```
Create the root subvolumes
```sh
mount -t btrfs /dev/mapper/root /mnt # mount the root partition
cd /mnt # navigate to the partition
btrfs subvolumes create root /mnt # create root subvolume
btrfs subvolumes create swap # create swap subvolume
btrfs subvolumes create snapshots # create snapshots subvolume
btrfs subvolumes create var # create var subvolume
ls # to check the subvolumes
cd /
umount -R /mnt
```
Create the home subvolumes
```sh
mount -t btrfs /dev/mapper/home /mnt # mount the home partition
cd /mnt # navigate to the partition
btrfs subvolumes create home /mnt # create home subvolume
ls # to check the subvolume
cd /
umount -R /mnt
```
#### Create the mounting point and mount the subvolumes
```sh
mkdir -p /mnt/swap
mkdir /mnt/snapshots
mkdir /mnt/var
mkdir /mnt/home
mkdir /mnt/boot
mkdir /mnt/boot/efi
```
Mount the subvolumes
```sh
mount -t btrfs -o subvol=root /dev/mapper/linux /mnt # mount root subvol to /mnt
mount -t btrfs -o subvol=swap /dev/mapper/linux /mnt/swap # mount swap subvol to /mnt/swap
mount -t btrfs -o subvol=snapshots /dev/mapper/linux /mnt/snapshots # mount snapshots subvol to /mnt/snapshots
mount -t btrfs -o subvol=var /dev/mapper/linux /mnt/var # mount var subvol to /mnt/var
```
Mount the boot volumes
```sh
mount /dev/sdXN /mnt/boot # mount boot volume (eg. /dev/sda2) to /mnt/boot
mount /dev/sdXN /mnt/boot/efi # mount EFI volume (eg. /dev/sda1) to /mnt/boot/efi
```
Make swap file
```sh
cd /mnt/swap
dd if=/dev/zero of=swapfile bs=1M count=1024 # create the swap file (in this example you can create a 1GB swap file, if you want 16GB swap file set count=16384)
chmod 0600 swapfile # set the security permission to swap file
swapon swapfile # activate the swap on the swapfile
```

### Arch system installation
Install arch base system
```sh
cd /mnt
pacstrap -i /mnt base base-devel efibootmgr grub networkmanager vim linux linux-firmware linux-headers # install the arch basic system
```

Create the fstab
```sh
genfstab -U /mnt > /mnt/etc/fstab # generate the fstab file
```

Chroot to the brand new arch installation
```sh
arch-chroot /mnt
```

### Arch configuration
Set arch root password
```sh
passwd
```
Set locale
```sh
vim /etc/locale.gen # search your language and uncomment your UTF-8 language
locale-gen # generate locale
echo LANG=it_IT > /etc/locale.conf # (eg. it_IT, en_US, en_GB, ...)
echo KEYMAP=it > /etc/vconsole.conf # set the keymap
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime # set the timezone
hwclock --systohc # set the clock
```
#### Set the hostname and hosts
```sh
echo archlinux > /etc/hostname # where archlinux is your hostname
vim /etc/hosts # and insert your host
```

>127.0.0.1		localhost	yourhostname   
>::1				 	localhost	yourhostname   
>127.0.1.1		yourhostname.localdomain	yourhostname

#### Grub config
Set the grub config and insert `cryptdevice=/dev/sdaX:yourhostname` into `GRUB_CMDLINE_LINUX=""` where sdaX is your linux partition    

```sh
vim /etc/default/grub
```

> GRUB_CMDLINE_LINUX="cryptdevice/dev/sda3:archlinux"

#### Config mkinitcpio.conf
Configure mkinitcpio.conf and insert `encrypt` before `filesystems` into the `HOOKS` field   

```sh
vim /etc/mkinitcpio.conf
```

> HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)

Apply mkinitcpio changes
```sh
`mkinitcpio -p linux`
```

#### Install Grub
```sh
grub-install --boot-directory /boot --efi-directory /boot/efi /dev/sdXN # where /dev/sdXN is the boot partition (eg. /dev/sda2)
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg # to create the Arch sub-menu
```

### Installation process completed: reboot, add user, activate network and install software as needed
Exit from arch-chroot
```sh
exit
```

Reboot the system
```sh
reboot
```

Login with root

#### Start Network Manager
This is intended for ethernet connection, not for WiFi connection

```sh
systemctl start NetworkManager
systemctl enable NetworkManager
ping google.com # to check the network configuration
```

Install vi
```sh
pacman -Syu vi
```

#### Add and configure user
```sh
useradd -m -d /home/username username # to create a specific user
passwd username # to change its password
usermod -G -a wheel username # add username to wheel group (sudo)
visudo
```
Uncomment the line `# %wheel ALL=(ALL) ALL`

Logout from root
```sh
exit
```

login with "username"

#### Install the software as needed (just an example)
```sh
sudo pacman -Syu plasma sddm kdednsutils vim tmux htop bpytop libreoffice-still git wget networkmanager-openvpn neofetch powerline-fonts ttf-fira-code starship barrier notepadqq joplin joplin-dektop ranger topgrade bash-completion xorg-xinput rofi dmenu networkmanager-dmenu-git polybar wmctrl atom gitkraken pycharm-community-edition
```
