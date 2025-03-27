#!/bin/bash

text=""
echo "Input text:"
read text
text=$(echo "$text" | tr -d '.,')

for word in $text; do
    if grep -q -i -w "^$word$" /usr/share/dict/words; then
        echo -n "$word "
    else
        echo -en "\033[31m$word\033[0m "
    fi
done
echo
