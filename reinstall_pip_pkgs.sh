#!/bin/bash

# Check if the file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <package-file>"
  exit 1
fi

# Read the file line by line
while IFS= read -r package; do
  # Skip empty lines
  if [ -z "$package" ]; then
    continue
  fi

  echo "Processing package: $package"

  # Uninstall the package
  echo "Uninstalling $package..."
  pip uninstall -y "$package"

  # Check if uninstallation was successful
  if [ $? -eq 0 ]; then
    echo "Successfully uninstalled $package"
  else
    echo "Failed to uninstall $package"
    continue
  fi

  # Install the package
  echo "Installing $package..."
  pip install "$package"

  # Check if installation was successful
  if [ $? -eq 0 ]; then
    echo "Successfully installed $package"
  else
    echo "Failed to install $package"
  fi

done < "$1"
