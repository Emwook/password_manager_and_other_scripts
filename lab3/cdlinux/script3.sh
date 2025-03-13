#!/bin/bash
grep "OK DOWNLOAD" cdlinux.ftp.log | cut -d '"' -f 2,4 | grep "\.iso$" | sort | uniq | sed "s#.*/##" | sort > abc.txt
cat cdlinux.www.log | cut -d '"' -f 2,3 | tr '"' " " | cut -d " " -f 2,5 | grep "\.iso 200$" | sort | sed "s#.*/##" | cut -d " " -f 1 | sort >> abc.txt
cat abc.txt | sort | uniq -c | sort
rm abc.txt