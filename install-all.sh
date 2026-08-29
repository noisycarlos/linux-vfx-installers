#!/bin/bash

current_script=$(basename "$0")

for file in *.sh; do
  if [ "$file" != "$current_script" ] && [[ "$file" != uninstall* ]]; then
    bash ./${file}
  fi
done
