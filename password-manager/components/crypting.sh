# Encrypt the temporary file and save it as the password file
encrypt_file() {
    echo "$MAGIC_HEADER" > "${TEMP_FILE}.new"
    tail -n +2 "$TEMP_FILE" >> "${TEMP_FILE}.new"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "${TEMP_FILE}.new" -out "$PASSWORD_FILE" -k "$MASTER_PASS"
    rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
}

# Decrypt the password file, check for validity, and verify the header
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
