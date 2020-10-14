#! /bin/bash

echo "Arch bootstrap v1.0"
echo "           by Rappy"
echo ""

echo "Loading the configuration file..."
source ./arch-bootstrap.conf

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