#!/bin/bash

app_name="Fusion"

installer_location=/home/$USER/Downloads
if [ $# -gt 0 ]; then
  installer_location="$1"
fi

installer_path_compressed=$(find "$installer_location" -maxdepth 1 -type f \( -name 'Blackmagic_Fusion_Studio_*_Linux.zip' -o -name 'Blackmagic_Fusion_Studio_*_Linux.tar.tar' \) | sort -V | tail -n 1)

if [ ! -f "$installer_path_compressed" ]; then
  echo "--- Skipping installation of ${app_name}, no installers found."
  exit 1
fi

installer_name="$(basename ${installer_path_compressed%_Linux.*})"

echo "----- Found installer for $installer_name -----"

installer_dir=$installer_location/$installer_name

mkdir $installer_dir -p
# rm -f $installer_dir/* 2>/dev/null

case "$installer_path_compressed" in
*.zip)
  echo "--- Unziping $installer_name..."
  unzip -q -n "$installer_path_compressed" -d "$installer_dir"
  ;;
*.tar.tar)
  echo "--- Uncompressing $installer_name..."
  tar -xf "$installer_path_compressed" --directory="$installer_dir" --skip-old-files --keep-old-files
  ;;
esac

installer_path=$(find "$installer_dir" -maxdepth 1 -type f -name 'Blackmagic_Fusion_Studio_Linux_*_installer.run')

if [ ! -f "$installer_path" ]; then
  echo "--- Error. Could not find uncompressed installer"
  exit 1
fi

version=$(echo ${installer_path} | sed -n 's/.\/Blackmagic_Fusion_Studio_Linux_\([0-9.]*\)_installer.run/\1/p')
echo "--- Installing ${app_name} v${version}..."
sudo SKIP_PACKAGE_CHECK=1 ${installer_path} -i -y

echo "--- Installing dependencies..."
if command -v dnf &>/dev/null; then
  sudo dnf install apr apr-util libxcb xcb-util-cursor xcb-util-damage
elif command -v apt &>/dev/null; then
  sudo apt install libapr1 libaprutil1 libxcb-cursor0 libxcb-damage0
fi

echo "--- Finished installing ${app_name}"
