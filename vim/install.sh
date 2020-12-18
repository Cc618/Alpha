#!/bin/bash

# Installs vim syntax support in the ~/.vim folder
# Used to test the plugin, use a plugin manager instead of this file
DIR=~/.vim/pack/vendor/start/alpha
rm -rf "$DIR"
mkdir -p "$DIR"
cp -r . "$DIR"

echo Installed !
