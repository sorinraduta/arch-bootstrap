#! /bin/bash

echo "                   __       __                __       __                  "
echo "  ____ ___________/ /_     / /_  ____  ____  / /______/ /__________ _____  "
echo " / __ \`/ ___/ ___/ __ \   / __ \/ __ \/ __ \/ __/ ___/ __/ ___/ __ \`/ __ \\"
echo "/ /_/ / /  / /__/ / / /  / /_/ / /_/ / /_/ / /_(__  ) /_/ /  / /_/ / /_/ / "
echo "\__,_/_/   \___/_/ /_/  /_.___/\____/\____/\__/____/\__/_/   \__,_/ .___/  "
echo "                                                                 /_/       "
echo "                                                  v1 by Rappy"
echo ""

echo "Loading the Arch configuration file..."
source ./arch.conf

# Config variables
echo "Device: $device"
echo "Main partition size: $main_partition_size"
echo "Boot partition size: $boot_partition_size"
echo "Swap size: $swap_size"
echo "Root size: $root_size"
echo "Home size: $home_size"
echo "General boostrap script path: $general_bootstrap_script"
echo ""

# Internal variables
boot_partition=${device}1
main_partition=${device}2


echo "Creating the paritions..."
sleep 1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $device
g # Create a new empty GPT partition table
n # Add a new partition (boot)
  # Partition number (default 1)
  # First sector (default)
+$boot_partition_size # Last sector
Y # Confirmation in case any signature already exists on these sectors (if it doesn't, an error message will appear)
t # Change partition type
1 # Change partition type to EFI System
n # Add a new partition (the main one)


+$main_partition_size
Y # Confirmation in case any signature already exists on these sectors (if it doesn't, an error message will appear)
w # Write table to disk and exit
EOF
echo "Partitions successfully created."


echo "Creating the physical & logical volumes..."
sleep 1
# Create LUKS encrypted container
cryptsetup -vy --batch-mode luksFormat $main_partition

# Open the container
cryptsetup open $main_partition luks

# Create a physical volume on top of the opened LUKS container
pvcreate -ffy /dev/mapper/luks

# Create the volume group, adding the previously created physical volume to it
vgcreate -fy $volume_group_name /dev/mapper/luks

# Create all your logical volumes on the volume group:
lvcreate -L $swap_size $volume_group_name -n swap
lvcreate -L $root_size $volume_group_name -n root
lvcreate -l $home_size $volume_group_name -n home
echo "Physical & logical volumes successfully created."


echo "Formatting logical volumes..."
sleep 1
mkfs.fat -F32 $boot_partition
mkfs.ext4 -F -L root /dev/$volume_group_name/root
mkfs.ext4 -F -L home /dev/$volume_group_name/home
mkswap /dev/$volume_group_name/swap
echo "Logical volumes successfully formatted..."


echo "Mounting the filesystem..."
sleep 1
mount /dev/$volume_group_name/root /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/$volume_group_name/home /mnt/home
mount $boot_partition /mnt/boot
swapon /dev/$volume_group_name/swap
echo "Filesystem successfully mounted."


echo "Installing the essential packages..."
sleep 1
pacstrap /mnt base base-devel linux linux-firmware grub vim networkmanager go git lvm2 efibootmgr
echo "Essential packages successfully installed."


echo "Applying final settings..."
sleep 1
# Fstab
genfstab -pU /mnt >> /mnt/etc/fstab

# Boot loader kernel params (GRUB)
grub_default_config=/mnt/etc/default/grub
grub_cmdline_key=GRUB_CMDLINE_LINUX_DEFAULT
grub_cmdline_value="cryptdevice=$main_partition:luks root=/dev/$volume_group_name/root quiet"
sed -c -i "s/\($grub_cmdline_key *= *\).*/\1$grub_cmdline_value/" $grub_default_config

# Initramfs
initram_config=/mnt/etc/mkinitcpio.conf
initram_hooks_key=HOOKS
initram_hooks_value=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)
sed -c -i "s/\($initram_hooks_key *= *\).*/\1$initram_hooks_value/" $initram_config
mkinitcpio -p linux
echo "Settings successfully applied."


echo "Installing the boot loader..."
sleep 1
# Install GRUB
grub-install --efi-directory=/mnt/boot $boot_partition
grub-mkconfig -o /boot/grub/grub.cfg
echo "Bootloader successfully installed."


# Change root into the new system
arch-chroot /mnt

source $general_bootstrap_script


# Cleanup
sleep 1
umount -R /mnt
echo "Your Arch installation is done!"
echo "Now you can reboot."
