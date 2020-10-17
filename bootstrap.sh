#! /bin/bash

echo "Arch bootstrap v1.0"
echo "           by Rappy"
echo ""

echo "Loading the configuration file..."
source ./arch-bootstrap.conf

# Config variables
echo "Device: $device"
echo "Main partition size: $main_partition_size"
echo "Boot partition size: $boot_partition_size"
echo "Swap size: $swap_size"
echo "Root size: $root_size"
echo "Home size: $home_size"
echo "Volume group name: $volume_group_name"
echo "Local time: $local_time"
echo "Language: $language"
echo "Hostname: $hostname"
echo ""

# Internal variables
boot_partition=${device}1
main_partition=${device}2


echo "Creating the paritions..."
echo cat << EOF | fdisk $device
d
g
n


$boot_partition_size
t
1
n


$main_partition_size
w
EOF
echo "Partitions successfully created."


echo "Creating the physical & logical volumes..."
# Create LUKS encrypted container
cryptsetup -vy luksFormat $main_partition

# Open the container
cryptsetup open $main_partition luks

# Create a physical volume on top of the opened LUKS container
pvcreate /dev/mapper/luks

# Create the volume group, adding the previously created physical volume to it
vgcreate $volume_group_name /dev/mapper/luks

# Create all your logical volumes on the volume group:
lvcreate -L $swap_size $volume_group_name -n swap
lvcreate -L $root_size $volume_group_name -n root
lvcreate -l $home_size $volume_group_name -n home
echo "Physical & logical volumes successfully created."


echo "Formatting logical volumes..."
mkfs.fat -F32 $boot_partition
mkfs.ext4 -L root /dev/$volume_group_name/root
mkfs.ext4 -L home /dev/$volume_group_name/home
mkswap /dev/$volume_group_name/swap
echo "Logical volumes successfully formatted..."


echo "Mounting the filesystem..."
mount /dev/$volume_group_name/root /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/$volume_group_name/home /mnt/home
mount $boot_partition /mnt/boot
swapon /dev/$volume_group_name/swap
echo "Filesystem successfully mounted."

echo "Installing the essential packages..."
pacstrap /mnt base base-devel linux linux-firmware grub vim networkmanager go git lvm2 efibootmgr
echo "Essential packages successfully installed."


echo "Applying final settings..."
# Fstab
genfstab -pU /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt

# Localization
ln -sf /usr/share/zoneinfo/$local_time /etc/localtime
echo $language UTF-8 > /etc/locale.gen
locale-gen
echo LANG=$language > /etc/locale.conf
export LANG=$language
hwclock -w

# Network configuration
echo $hostname >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
systemctl enable NetworkManager

# Boot loader kernel params (GRUB)
grub_default_config=/etc/default/grub
grub_cmdline_key=GRUB_CMDLINE_LINUX_DEFAULT
grub_cmdline_value="cryptdevice=$main_partition:luks root=/dev/$volume_group_name/root quiet"
sed -c -i "s/\($grub_cmdline_key *= *\).*/\1$grub_cmdline_value/" $grub_default_config

# Initramfs
initram_config=/etc/mkinitcpio.conf
initram_hooks_key=HOOKS
initram_hooks_value=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)
sed -c -i "s/\($initram_hooks_key *= *\).*/\1$initram_hooks_value/" $initram_config
mkinitcpio -p linux
echo "Settings successfully applied."


echo "Installing the boot loader..."
# Install GRUB
grub-install --efi-directory=/boot --recheck --removable /dev/sdc
grub-mkconfig -o /boot/grub/grub.cfg
echo "Bootloader successfully installed."


echo "Please set a the root password:"
# Set root password
passwd


# Cleanup
exit
umount -R /mnt
echo "Your Arch installation is done!"
echo "Now you can reboot."