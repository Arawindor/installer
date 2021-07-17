# Install Arch with full disk encryption (BTRFS) and separated encrypted home partition

## With *home* on a separate disk volume

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

### Disks setup
1. set keyboard layout
	`loadkeys it`
2. check internet connection
	`ping google.com`
3. set daytime
	`timedatectl set ntp true`
4. lisk all disk installed
	`lsblk`
5. 	disk setup
	`fdisk /dev/sdX`
	`m` (make partition)
	`g` (create empty GPT partition)
	`w` (write partition on disk)
6. create partition
	`cfdisk`	
7. create EFI partition
	select `New`
	select the size `256M` (eg.: 256 MB)
	select `EFI` in `Type`
8. create Boot partition
	select `New`
	select the size `512M` (eg.: 512 MB)
	leave `Linux` in `Type`
9. create Linux partition
	select `New`
	select the size `120G` (eg.: 120 GB)
	leave `Linux` in `Type`
10. create Home partition
	select `New`
	select the size `120G` (eg.: 120 GB)
	leave `Linux` in `Type`
11. write the modification to disk
	select `Write` 
	confirm with `yes`
	select `Quit` to quit cfdisk
12.  format the partitions
	`mkfs.vfat -n "EFI System" /dev/sdXN` where XN is the EFI partition (eg. /dev/sda1)
	`mkfs.ext4 -L boot /dev/sdXN` where XN is the Boot partition (eg. /dev/sda2)
	`mkfs.ext4 -L root /dev/sdXN` where XN is the root partition (eg. /dev/sda3)
	`mkfs.ext4 -L home /dev/sdXN` where XN is the home partition (eg. /dev/sda4)
13. load the encryption modules
	`modprobe dm-crypt`
	`modprobe dm-mod`
14. configure the encryption
	`cryptsetup luksFormat -v -s 512 -h sha512 /dev/sdXN` where XN is the root partition (eg. /dev/sda3) and insert the ecnryption desired password
	`cryptsetup luksFormat -v -s 512 -h sha512 /dev/sdXN` where XN is the home partition (eg. /dev/sda4) and insert the ecnryption desired password
15. open encrypted partition
	`cryptsetup open /dev/sdXN label` where XN is the root partition (eg. /dev/sda3)  and the desired label (eg. linux) and enter the password
	`cryptsetup open /dev/sdXN label` where XN is the home partition (eg. /dev/sda4)  and the desired label (eg. home) and enter the password
16. check if the encrypted partition are opened
	 `ls /dev/mapper/`
17.  format with BTRFS the opened partition and create volumes
	`mkfs.btrfs -L root /dev/mapper/linux` for the root partition
	`mkfs.btrfs -L home /dev/mapper/home` for the home partition
		1. create the root subvolumes
	 `mount -t btrfs /dev/mapper/root /mnt` mount the root partition
	`cd /mnt` navigate to the partition
	`btrfs subvolumes create root /mnt` create root subvolume
	`btrfs subvolumes create swap` create swap subvolume
	`btrfs subvolumes create snapshots` create snapshots subvolume
	`brfs subvolumes create var` create var subvolume
	`ls` to check the subvolumes
	`cd /`
	`umount -R /mnt`
		2.  create the home subvolumes
	 `mount -t btrfs /dev/mapper/home /mnt` mount the home partition
	`cd /mnt` navigate to the partition
	`btrfs subvolumes create home /mnt` create home subvolume
	`ls` to check the subvolume
	`cd /`
	`umount -R /mnt`
20. create the mounting point
`mkdir -p /mnt/swap`
`mkdir /mnt/snapshots`
`mkdir /mnt/var`
`mkdir /mnt/home`
`mkdir /mnt/boot`
`mkdir /mnt/boot/efi`
20. mount the subvolumes
`mount -t btrfs -o subvol=root /dev/mapper/linux /mnt` mount root subvol to /mnt
`mount -t btrfs -o subvol=swap /dev/mapper/linux /mnt/swap` mount swap subvol to /mnt/swap
`mount -t btrfs -o subvol=snapshots /dev/mapper/linux /mnt` mount snapshots subvol to /mnt/snapshots
`mount -t btrfs -o subvol=var /dev/mapper/linux /mnt/var` mount var subvol to /mnt/var
21.  mount boot volumes
`mount /dev/sdXN /mnt/boot` mount boot volume (eg. /dev/sda2) to /mnt/boot
`mount /dev/sdXN /mnt/boot/efi` mount EFI volume (eg. /dev/sda1) to /mnt/boot/efi
22. make swap file
`cd /mnt/swap`
`dd if=/dev/zero of=swapfile bs=1M count=1024` create the swap file (in this example you can create a 1GB swap file, if you want 16GB swap file set count=16384)
`chmod 0600 swapfile` set the security permission to swap
`swapon swapfile` activate the swap on the swapfile

### Arch installation
1. install arch system
`cd /mnt`
`pacstrap -i /mnt base base-devel efibootmgr grub networkmanager vim linux linux-firmware linux-headers` install the arch basic system
24. create the fstab
`genfstab -U /mnt > /mnt/etc/fstab` generate the fstab file
25. chroot to the brand new arch installation
`arch-chroot /mnt`

### Arch configuration
1. set arch root password
`passwd`
2. set locale
`vim /etc/locale.gen` search your language and uncomment the UTF-8 language
`locale-gen` generate locale
`echo LANG=it_IT > /etc/locale.conf` (eg. it_IT, en_US, en_GB, ...)
`echo KEYMAP=it > /etc/vconsole.conf` set the keymap
`ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime` set the timezone
`hwclock --systohc --utc+1` set the clock
3. set the hostname
`echo archlinux > /etc/hostname` where archlinux is your hostname
29. set hosts
`vim /etc/hosts` and insert your host
>127.0.0.1		localhost	yourhostname
>::1				 localhost	yourhostname
4. set the grub config
`vim /et/default/grub` and insert `cryptdevice=/dev/sdaX:yourhostname` into `GRUB_CMDLINE_LINUX=""` where sdaX is your linux partition and
> `GRUB_CMDLINE_LINUX="cryptdevice/dev/sda3:archlinux"`
5. configure mkinitcpio.conf
`vim /etc/mkinitcpio.conf` and insert `encrypt` before `filesystems` into the `HOOKS` field
	> `HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)`
6. apply mkinitcpio changes
`mkinitcpio -p linux`
7. install Grub
`grub-install --boot-directory /boot --efi-directory /boot/efi /dev/sdXN` where /dev/sdXN is the boot partition (eg. /dev/sda2)
`grub-mkconfig -o /boot/grub/grub.cfg`
`grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg` to create the Arch menu

### Installation process completed: reboot, add user, activate network and install software as needed
1. exit from arch-chroot
`exit`
2. reboot the system
`reboot`
3. login with root
4. start Network Manager
`systemctl start NetworkManager`
`systemctl enable NetworkManager`
`ping google.com` to check the network configuration
5. install vi
`pacman -Syu vi`
6. add and configure user
`useradd -m -d /home/username username` to create a specific user
`passwd username`
`usermod -G -a wheel username` add username to wheel group (sudo)
`visudo` and uncomment the line `# %wheel ALL=(ALL) ALL`
7. logout from root and login with username
`exit`
login with username
8. install all the software as needed (just an example)
>`sudo pacman -Syu plasma sddm kdednsutils vim tmux htop bpytop libreoffice-still git wget networkmanager-openvpn neofetch powerline-fonts ttf-fira-code starship barrier notepadqq joplin joplin-dektop ranger topgrade bash-completion xorg-xinput rofi dmenu networkmanager-dmenu-git polybar wmctrl atom gitkraken pycharm-community-edition`

