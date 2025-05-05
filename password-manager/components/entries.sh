# Generate a password based on user-specified length and complexity
generate_password() {
    local length complexity charset
    length=$(zenity --entry \
        --title="Password Length" \
        --text="Enter password length:" \
        --entry-text="$DEFAULT_PASS_LENGTH") || return 1

    complexity=$(zenity --list --title="Password Complexity" \
        --column="Level" "Basic (letters only)" "Moderate (letters and numbers)" "Strong (letters, numbers, symbols)") || return 1

    case "$complexity" in
        *Basic*) charset='A-Za-z' ;;
        *Moderate*) charset='A-Za-z0-9' ;;
        *Strong*) charset='A-Za-z0-9!@#$%^&*()-_=+' ;;
        *) charset='A-Za-z0-9' ;;
    esac

    openssl rand -base64 48 | tr -dc "$charset" | head -c "$length"
}

# Add a new password entry, prompting the user for service, username, and password
add_entry() {
    local form service user pass
    form=$(zenity --forms --title="Add Entry" \
        --add-entry="Service Name" \
        --add-entry="Username" \
        --width=600 \
        --height=400 \
        --add-password="Password (leave empty to generate)")
    [ $? -ne 0 ] && return
    service=$(echo "$form" | cut -d'|' -f1)
    user=$(echo "$form" | cut -d'|' -f2)
    pass=$(echo "$form" | cut -d'|' -f3)

    # If no password provided, generate one
    if [ -z "$pass" ]; then
        pass=$(generate_password) || return
    fi

    decrypt_file
    echo "$service | $user | $pass" >> "$TEMP_FILE"
    encrypt_file
    zenity --info --text="Entry added for $service."
}

# Show all stored entries in a scrollable window
show_entries() {
    decrypt_file
    tail -n +2 "$TEMP_FILE" | zenity --text-info --title="Stored Entries"
    encrypt_file
}

# Copy a password to clipboard based on the selected service name
copy_password() {
    local service match pass
    service=$(zenity --entry --title="Copy Password" --text="Enter service name:") || return
    decrypt_file
    match=$(grep "^$service |" "$TEMP_FILE")
    encrypt_file

    # If no matching entry found, show an error
    if [ -z "$match" ]; then
        zenity --error --text="No entry found for $service."
        return
    fi

    pass=$(echo "$match" | awk -F' | ' '{print $NF}')
    echo -n "$pass" | copy_to_clipboard
    zenity --info --text="Password copied to clipboard."
}
