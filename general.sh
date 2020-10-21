#! /bin/bash

echo "   ______                           __   __                __       __                 "
echo "  / ____/__  ____  ___  _________ _/ /  / /_  ____  ____  / /______/ /__________ _____ "
echo " / / __/ _ \/ __ \/ _ \/ ___/ __ \`/ /  / __ \/ __ \/ __ \/ __/ ___/ __/ ___/ __ \`/ __ \\"
echo "/ /_/ /  __/ / / /  __/ /  / /_/ / /  / /_/ / /_/ / /_/ / /_(__  ) /_/ /  / /_/ / /_/ /"
echo "\____/\___/_/ /_/\___/_/   \__,_/_/  /_.___/\____/\____/\__/____/\__/_/   \__,_/ .___/ "
echo "                                                                              /_/      "
echo "                                                  v1 by Rappy                          "
echo ""

echo "Loading the general configuration file..."
source ./general.conf

# Config variables
echo "Local time: $local_time"
echo "Language: $language"
echo "Hostname: $hostname"
echo ""

# Localization
echo "Setting up localization..."
ln -sf /usr/share/zoneinfo/$local_time /etc/localtime
echo $language UTF-8 > /etc/locale.gen
locale-gen
echo LANG=$language > /etc/locale.conf
export LANG=$language
hwclock -w
echo "Localization set."

# Network configuration
echo "Setting up network configuration..."
echo $hostname >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
systemctl enable NetworkManager
echo "Network configuration set..."

echo "Please set a the root password:"
sleep 1
# Set root password
passwd

exit
