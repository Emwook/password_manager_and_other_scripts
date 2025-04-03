#!/bin/bash

echo "[" > abc.json

cat world.csv | cut -d '"' -f 1 | sed 's/,$//'| grep "EUROPE" | cut -d ',' -f 1,3,4 | sed 's/{/\t{"country": "/' | sed 's/ ,/", "population": /' |sed 's/\(.*\),/\1, "area": /'| sed 's/$/},/' >> abc.json 

sed -i '' '$ s/},$/}/' abc.json

echo "]" >> abc.json
