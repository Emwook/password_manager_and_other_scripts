#!/bin/bash

# Author           : Emilia Łukasiuk (s203620@student.pg.edu.pl)
# Created On       : 27.04.25
# Last Modified By : Emilia Łukasiuk
# Last Modified On : 05.05.25
# Version          : 0.6
#
# Description      : password manager with openssl - version 0.6, 
#                    encryption options, copying to clipboard, getops for -v/-h
#                    config added, component based build, zenity as UI
#                    
# Licensed under GPL


DIR="$(dirname "$0")"
source "$DIR/components/crypting.sh"
source "$DIR/components/clipboard.sh"
source "$DIR/components/entries.sh"
source "$DIR/components/version.sh"

PASSWORD_FILE="$DIR/data/passwords.enc"
TEMP_FILE="/tmp/passwords.tmp"
MAGIC_HEADER="PASSWORD_MANAGER"
MASTER_PASS=""

CONFIG_FILE="$HOME/.password-manager/config"

# Check and load configuration file or use defaults
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    DEFAULT_PASS_LENGTH=16
fi

zenity_password() {
    zenity --password --title="$1" --width=600 --height=400 --ok-label="OK" --cancel-label="Cancel"
}

zenity_main_menu() {
    zenity --list \
        --title="Password Manager" \
        --column="Option" \
        "Add Entry" "Show Entries" "Copy Password" \
        --width=600 --height=400 --ok-label="Select" --cancel-label="Exit"
}

while getopts ":hv" option; do
    case "$option" in
        h) show_help ;;
        v) show_version ;;
        *) show_help ;;
    esac
done

# Prompt user for master password and handle file encryption/decryption
if [ ! -f "$PASSWORD_FILE" ]; then
    MASTER_PASS=$(zenity_password "Set Master Password") || exit 1
    echo "$MAGIC_HEADER" > "$TEMP_FILE"
    encrypt_file
else
    MASTER_PASS=$(zenity_password "Enter Master Password") || exit 1
    decrypt_file
    encrypt_file
fi

# Main loop to show options and execute actions based on user choice
while true; do
    OPTION=$(zenity_main_menu) || exit 0
    case "$OPTION" in
        "Add Entry") add_entry ;;
        "Show Entries") show_entries ;;
        "Copy Password") copy_password ;;
    esac
done

rm -f "$TEMP_FILE"
