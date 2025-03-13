#!/bin/bash
cat cdlinux.www.log | cut -d '"' -f 2,3 | tr '"' " " | cut -d " " -f 2,5 | grep "\.iso 200$" | sort | uniq -c | sort