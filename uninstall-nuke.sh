#!/bin/bash

app_name="Nuke"
nuke_install_basepath=/opt/Nuke

# Find all installed Nuke versions (directories matching Nuke*)
installed_versions=($(find ${nuke_install_basepath} -maxdepth 1 -type d -name 'Nuke*' -printf '%f\n' 2>/dev/null | sed 's/Nuke//' | sort -V))

if [ ${#installed_versions[@]} -eq 0 ]; then
  echo "--- No ${app_name} installations found."
  exit 0
fi

echo "--- Found ${#installed_versions[@]} installed ${app_name} version(s):"

if command -v gum &>/dev/null; then
  version=$(printf '%s\n' "${installed_versions[@]}" | gum choose --header="--- Select version to uninstall:")
else
  echo "--- Select version to uninstall:"
  select ver in "${installed_versions[@]}"; do
    if [ -n "$ver" ]; then
      version="$ver"
      break
    fi
    echo "--- Invalid selection, try again."
  done
fi

if [ -z "$version" ]; then
  echo "--- Cancelled."
  exit 0
fi
vnum="${version%%v*}"
installation_dir_name="Nuke${version}"

echo "--- Uninstalling ${app_name} version ${version}..."

echo "--- Removing ${nuke_install_basepath}/${installation_dir_name}..."
sudo rm -rf "${nuke_install_basepath}/${installation_dir_name}"

echo "--- Removing desktop shortcuts..."
for variation in "Nuke" "Nuke Indie" "Nuke Non-commercial" "NukeX"; do
  shortcut_filename=$(echo "${variation}_${version}" | tr -d ' .')
  sudo rm -f ~/.local/share/applications/${shortcut_filename}.desktop
done

# Remove the icon if this was the last installed version
remaining_versions=($(find ${nuke_install_basepath} -maxdepth 1 -type d -name 'Nuke*' -printf '%f\n' 2>/dev/null))
if [ ${#remaining_versions[@]} -eq 0 ]; then
  echo "--- Removing last ${app_name} installation, cleaning up base directory..."
  sudo rm -f "${nuke_install_basepath}/nuke.png"
  sudo rmdir "${nuke_install_basepath}" 2>/dev/null
fi

echo "--- Finished uninstalling ${app_name} version ${version}"
