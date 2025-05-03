#!/bin/bash

# Author           : Emilia Łukasiuk (s203620@student.pg.edu.pl)
# Created On       : 27.04.25
# Last Modified By : Emilia Łukasiuk
# Last Modified On : 03.05.25
# Version          : 0.4
#
# Description      : password manager with openssl - version 0.4, 
#                    basic function with encryption options and copying to clipboard,
#                    Zenity used as interface
# Licensed under GPL

PASSWORD_FILE="passwords.enc"
TEMP_FILE="passwords.tmp"
MAGIC_HEADER="PASSWORD_MANAGER"

MASTER_PASS=""

copy_to_clipboard() {
    if command -v pbcopy &> /dev/null; then
        pbcopy
    elif command -v xclip &> /dev/null; then
        xclip -selection clipboard
    elif command -v xsel &> /dev/null; then
        xsel --clipboard --input
    else
        zenity --error --text="No clipboard utility found. Install pbcopy, xclip, or xsel."
        return 1
    fi
}

encrypt_file() {
    echo "$MAGIC_HEADER" > "${TEMP_FILE}.new"
    tail -n +2 "$TEMP_FILE" >> "${TEMP_FILE}.new"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "${TEMP_FILE}.new" -out "$PASSWORD_FILE" -k "$MASTER_PASS"
    rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
}

decrypt_file() {
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$PASSWORD_FILE" -out "$TEMP_FILE" -k "$MASTER_PASS" 2>/dev/null
    if [ ! -f "$TEMP_FILE" ]; then
        zenity --error --text="Failed to decrypt file. Wrong master password?" --ok-label="Got it"
        exit 1
    fi
    read -r first_line < "$TEMP_FILE"
    if [ "$first_line" != "$MAGIC_HEADER" ]; then
        zenity --error --text="Incorrect master password." --ok-label="Retry"
        rm -f "$TEMP_FILE"
        exit 1
    fi
}

generate_password() {
    PASS_LENGTH=$(zenity --entry --title="Password Length" --text="Enter password length:" --width=400 --height=400 --ok-label="Generate" --cancel-label="Cancel") || return 1
    COMPLEXITY=$(zenity --list \
        --title="Password Complexity" \
        --column="Level" \
        "Basic (letters only)" \
        "Moderate (letters and numbers)" \
        "Strong (letters, numbers, symbols)" \
        --width=400 --height=400 --ok-label="Select" --cancel-label="Cancel") || return 1

    case "$COMPLEXITY" in
        *Basic*) CHAR_SET='A-Za-z' ;;
        *Moderate*) CHAR_SET='A-Za-z0-9' ;;
        *Strong*) CHAR_SET='A-Za-z0-9!@#$%^&*()-_=+' ;;
        *) CHAR_SET='A-Za-z0-9!@#$%^&*()-_=+' ;;
    esac

    PASSWORD=$(openssl rand -base64 48 | tr -dc "$CHAR_SET" | head -c "$PASS_LENGTH")
    echo "$PASSWORD"
}

add_entry() {
    FORM_DATA=$(zenity --forms --title="Add New Entry" \
        --width=400 --height=400 \
        --text="Fill in the fields below" \
        --separator="|" \
        --add-entry="Service Name" \
        --add-entry="Username" \
        --add-password="Password (leave empty to generate)" --ok-label="Save" --cancel-label="Cancel")

    [ $? -ne 0 ] && return

    SERVICE=$(echo "$FORM_DATA" | cut -d'|' -f1)
    USERNAME=$(echo "$FORM_DATA" | cut -d'|' -f2)
    PASSWORD=$(echo "$FORM_DATA" | cut -d'|' -f3)

    if [ -z "$PASSWORD" ]; then
        PASSWORD=$(generate_password) || return
    fi

    decrypt_file
    echo "$SERVICE | $USERNAME | $PASSWORD" >> "$TEMP_FILE"
    encrypt_file

    zenity --info --text="Entry added for $SERVICE." --width=400 --height=400 --ok-label="Back"
}

show_entries() {
    decrypt_file
    ENTRIES=$(tail -n +2 "$TEMP_FILE")
    encrypt_file
    zenity --text-info --title="Stored Entries" --width=400 --height=400 --filename=<(echo "$ENTRIES") --cancel-label="Back"
}

copy_password() {
    SERVICE=$(zenity --entry --title="Copy Password" --text="Enter service name:" --width=400 --height=400 --ok-label="Copy" --cancel-label="Cancel") || return
    decrypt_file
    
    MATCH=$(grep "^$SERVICE |" "$TEMP_FILE")
    encrypt_file

    if [ -z "$MATCH" ]; then
        zenity --error --text="No entry found for $SERVICE." --width=400 --height=400 --ok-label="Back"
        return
    fi

    PASSWORD=$(echo "$MATCH" | awk -F' | ' '{print $NF}')
    echo -n "$PASSWORD" | copy_to_clipboard && zenity --info --text="Password copied to clipboard." --width=400 --height=400 --ok-label="Close"
}

# Initial master password prompt
if [ ! -f "$PASSWORD_FILE" ]; then
    MASTER_PASS=$(zenity --password --title="Set Master Password" --width=400 --height=400 --ok-label="Proceed" --cancel-label="Cancel") || exit 1
    echo "$MAGIC_HEADER" > "$TEMP_FILE"
    encrypt_file
else
    MASTER_PASS=$(zenity --password --title="Enter Master Password" --width=400 --height=400 --ok-label="Login" --cancel-label="Cancel") || exit 1
    decrypt_file
    encrypt_file
fi

# Main loop
while true; do
    OPTION=$(zenity --list \
        --title="Password Manager" \
        --column="Option" \
        "Add Entry" \
        "Show Entries" \
        "Copy Password" --width=400 --height=400 --ok-label="Select" --cancel-label="Exit") || exit 0

    case "$OPTION" in
        "Add Entry") add_entry ;;
        "Show Entries") show_entries ;;
        "Copy Password") copy_password ;;
    esac

done
