#!/bin/bash
grep "OK DOWNLOAD" cdlinux.ftp.log | cut -d '"' -f 2,4 | grep "\.iso$" | sort | uniq | sed "s#.*/##" | sort | uniq -c | sort -r
| cut -d ' ' -f 9 |