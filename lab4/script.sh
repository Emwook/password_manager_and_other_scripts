#!/bin/bash

name=""
directory="~/"
content=""
depth=""
size=""

display_menu() {
    clear
    echo "1. file name: $name"
    echo "2. directory: $directory"
    echo "3. max depth: $depth"
    echo "4. file size: $size"
    echo "5. file content: $content"
    echo "6. search"
    echo "7. exit"
    echo -n "choose an option: "
}

while true
do
    display_menu
    choice=""
    read choice
    case $choice in
        1)
            echo "input file name"
            read -r name
            ;;

        2)
            echo "input directory"
            read -r directory
            ;;

        3)
            echo "input max depth"
            read -r depth
            ;;

        4)
            echo "input size"
            read -r size
            ;;

        5)
            echo "input file content"
            read -r content
            ;;

        6)
            echo "results:"
            find_command="find ${directory} -name "$name""
            if [ -n "$type" ]; then
                find_command="${find_command} -maxdepth "$depth""
            fi
            if [ -n "$size" ]; then
                find_command="${find_command} -size "$size""
            fi  
            if [ -n "$content" ]; then
                find_command="${find_command} -exec grep -l $content {} \;"
            fi
            eval "$find_command"
            echo "press enter, to look again."
            read -r
            ;;

        7)
            exit 0
            ;;

        *)
            echo -n "try again"
            ;;
    esac
done