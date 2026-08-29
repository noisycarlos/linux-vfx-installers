#!/bin/bash

current_script=$(basename "$0")

installer_location=/home/$USER/Downloads
if [ $# -gt 0 ]; then
  installer_location="$1"
fi

for file in *.sh; do
  if [ "$file" != "$current_script" ] && [[ "$file" != uninstall* ]]; then
    bash ./${file} $installer_location
  fi
done
