#!/bin/bash

# Author           : Emilia Łukasiuk (s203620@student.pg.edu.pl)
# Created On       : 27.04.25
# Last Modified By : Emilia Łukasiuk (s203620@student.pg.edu.pl)
# Last Modified On : 27.04.25
# Version          : 0.1
#
# Description      : password manager with openssl - version 1.0, 
#                    basic function without custom encryption options,
#                    terminal as interface, 
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

PASSWORD_FILE="passwords.enc"
TEMP_FILE="passwords.tmp"
MAGIC_HEADER="PASSWORD_MANAGER"

MASTER_PASS=""

encrypt_file() {
    echo "$MAGIC_HEADER" > "${TEMP_FILE}.new"
    tail -n +2 "$TEMP_FILE" >> "${TEMP_FILE}.new"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "${TEMP_FILE}.new" -out "$PASSWORD_FILE" -k "$MASTER_PASS"
    rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
}

decrypt_file() {
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$PASSWORD_FILE" -out "$TEMP_FILE" -k "$MASTER_PASS" 2>/dev/null
    if [ ! -f "$TEMP_FILE" ]; then
        echo "Failed to decrypt the file. Wrong master password?"
        exit 1
    fi
    read -r first_line < "$TEMP_FILE"
    if [ "$first_line" != "$MAGIC_HEADER" ]; then
        echo "Incorrect master password. Access denied."
        rm -f "$TEMP_FILE"
        exit 1
    fi
}

generate_password() {
    read -p "Enter password length: " PASS_LENGTH
    PASSWORD=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' | head -c "$PASS_LENGTH")
    echo "$PASSWORD"
}

add_entry() {
    read -p "Enter service name: " SERVICE
    read -p "Enter username: " USERNAME
    PASSWORD=$(generate_password)

    decrypt_file
    echo "$SERVICE | $USERNAME | $PASSWORD" >> "$TEMP_FILE"
    encrypt_file

    echo "Entry added for $SERVICE."
}

show_entries() {
    decrypt_file
    echo "Saved accounts:"
    tail -n +2 "$TEMP_FILE"
    encrypt_file
}

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "Creating a new password file."
    read -s -p "Set a master password: " MASTER_PASS
    echo
    echo "$MAGIC_HEADER" > "$TEMP_FILE"
    encrypt_file
else
    read -s -p "Enter your master password: " MASTER_PASS
    echo
    decrypt_file
fi

while true; do
    echo
    echo "---< PASSWORD MANAGER >---"
    echo "1. Add new password"
    echo "2. Show all entries"
    echo "3. Exit"
    read -p "Choose an option: " OPTION

    case $OPTION in
        1) add_entry ;;
        2) show_entries ;;
        3) echo "bye bye!"; exit 0 ;;
        *) echo "Invalid option!" ;;
    esac
done
