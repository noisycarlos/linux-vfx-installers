#!/bin/bash

app_name="Nuke"
installer_location=/home/$USER/Downloads

installer_path_compressed=$(find $installer_location -maxdepth 1 -type f -name 'Nuke*-linux-x86_64.tgz' | sort -V | tail -n 1)
installer_path=${installer_path_compressed%.tgz}.run
installer_filename=${installer_path##*/}

if [ -f "$installer_path_compressed" ] &&
  [ ! -f "$installer_path" ]; then
  echo "Uncompressing ${installer_path##*/}..."
  tar -xzf $installer_path_compressed -C $installer_location
fi

if [ ! -f "$installer_path" ]; then
  echo "--- Could not find .run file for tgz. Looking for any other .run file..."
  installer_path=$(find $installer_location -maxdepth 1 -type f -name 'Nuke*-linux-x86_64.tgz' | sort -V | tail -n 1)
fi

if [ ! -f "$installer_path" ]; then
  echo "--- Skipping installation of ${app_name}, no installers found."
  exit 1
fi

version=$(echo ${installer_filename} | sed -n 's/Nuke\([0-9.v]*\)-linux-x86_64.run/\1/p')

nuke_install_basepath=/opt/Nuke
installation_dir_name=Nuke${version}
vnum="${version%%v*}"

echo "--- Installing ${app_name} version ${version} - ${installer_filename}..."
echo "--- ${vnum} - ${installation_dir_name}"

# exit 0
if [ -d ${nuke_install_basepath}/${installation_dir_name} ]; then
  echo "--- Clearing destination..."
  sudo rm -r ${nuke_install_basepath}/${installation_dir_name}
fi

sudo chmod +x ${installer_path}
sudo ${installer_path} --accept-foundry-eula --prefix=${nuke_install_basepath}

echo "--- Moving application to bin directory..."
if [ ! -d "${nuke_install_basepath}" ]; then
  sudo mkdir ${nuke_install_basepath} >/dev/null
fi

# sudo mv ./${installation_dir_name} ${nuke_install_basepath}/

sudo cp ./nuke.png ${nuke_install_basepath}/nuke.png

echo "--- Installing dependencies..."
sudo apt install libglu1-mesa libglu1-mesa-dev -y

echo "--- Creating Application shortcuts..."
sudo mkdir -p ~/.local/share/applications/
sudo chmod -R 777 ~/.local/share/applications/
cd ~/.local/share/applications/

variations=(
  "Nuke:"
  "Nuke Indie:--indie"
  "Nuke Non-commercial:--nc"
  "NukeX:--nukex"
)

# Loop through each variation
for variation in "${variations[@]}"; do
  IFS=':' read -r name flag <<<"$variation"
  IFS=':' read -r name value <<<"$variation"
  shortcut_filename=$(echo "${name}_${version}" | tr -d ' .')

  echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Terminal=false
Type=Application
Name=${name} ${version}
Exec=${nuke_install_basepath}/${installation_dir_name}/Nuke${vnum} ${value}
Icon=${nuke_install_basepath}/nuke.png" >${shortcut_filename}.desktop
done

# echo "--- Cleanup..."
# if [ "${delete_installer}" = 1 ]; then
#   echo "deleting downloaded installer..."
#   rm ${installer_path}
#   sudo rm -r ./Nuke${version} >>/dev/null
# else
#   echo "leaving previously-existing installer in place..."
# fi
echo "--- Finished installing ${app_name}"
