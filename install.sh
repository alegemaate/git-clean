#!/bin/bash

set -e

# Determine install directory
if [ "$(uname)" = "Darwin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ "$(uname)" = "Linux" ]; then
  if [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
  else
    INSTALL_DIR="/usr/local/bin"
  fi
else
  echo "Unsupported OS: $(uname)"
  exit 1
fi

echo "Installing to $INSTALL_DIR"

# Use sudo if installing to a system directory and not running as root
if [ "$EUID" -ne 0 ] && [[ "$INSTALL_DIR" == /usr/* ]]; then
  sudo cp git-clean.sh "$INSTALL_DIR/git-clean"
  sudo chmod +x "$INSTALL_DIR/git-clean"
else
  cp git-clean.sh "$INSTALL_DIR/git-clean"
  chmod +x "$INSTALL_DIR/git-clean"
fi

echo "Done!"
