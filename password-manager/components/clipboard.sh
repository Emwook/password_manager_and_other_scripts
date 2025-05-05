# Copies the password to the clipboard using available utilities
copy_to_clipboard() {
    if command -v pbcopy &> /dev/null; then
        pbcopy
    elif command -v xclip &> /dev/null; then
        xclip -selection clipboard
    elif command -v xsel &> /dev/null; then
        xsel --clipboard --input
    else
        zenity --error --text="No clipboard utility found."
        return 1
    fi
}
