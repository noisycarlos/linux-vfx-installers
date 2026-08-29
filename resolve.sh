#!/bin/bash

app_name="DaVinci Resolve"

installer_location=/home/$USER/Downloads
if [ $# -gt 0 ]; then
  installer_location="$1"
fi

installer_path_compressed=$(find $installer_location -maxdepth 1 -type f -name 'DaVinci_Resolve_Studio_*_Linux.zip' | sort -V | tail -n 1)
if [ -f "$installer_path_compressed" ]; then
  installer_name="$(basename ${installer_path_compressed%_Linux.*})"
  echo "----- Found compressed installer for $installer_name -----"
  installer_dir=$installer_location/$installer_name
  mkdir $installer_dir -p
  echo "-- Unziping $installer_name..."
  unzip -q -n "$installer_path_compressed" -d "$installer_dir"
else
  echo "-- No compressed installers found for $app_name. Looking for uncompressed ones..."
  installer_dir=$installer_location
fi

installer_path=$(find "$installer_dir" -maxdepth 1 -type f -name 'DaVinci_Resolve_Studio_*_Linux.run')

if [ -f "$installer_path" ]; then
  echo "-- Found installer: $installer_path"
else
  echo "----- Skipping installation of ${app_name}, no installers found."
  exit 1
fi

version=$(echo ${installer_path} | sed -n 's/.\/DaVinci_Resolve_Studio_\([0-9.]*\)_Linux.run/\1/p')
echo "--- Installing ${app_name} version ${version}..."

# sudo SKIP_PACKAGE_CHECK=1 ${installer_path} -i -y

if command -v dnf &>/dev/null; then
  sudo dnf install apr apr-util libxcb xcb-util-cursor xcb-util-damage
elif command -v apt &>/dev/null; then
  sudo apt install libapr1 libaprutil1 libxcb-cursor0 libxcb-damage0
fi

echo "--- Moving uneeded libraries..."

sudo mkdir /opt/resolve/libs/unneeded
sudo mv /opt/resolve/libs/libgio* /opt/resolve/libs/unneeded/
sudo mv /opt/resolve/libs/libglib* /opt/resolve/libs/unneeded/
sudo mv /opt/resolve/libs/libgmodule* /opt/resolve/libs/unneeded/

echo "--- Finished installing ${app_name}"
