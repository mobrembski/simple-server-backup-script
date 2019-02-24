# simple-server-backup-script
This is my bash script for very simple backing-up node/server data.

Preface
-------------------------
I have some few servers in my home network. Basicly, server has following partitions layout:
 - /dev/sda1 - For /boot partition
 - /dev/sda2 - For / partition
 - /dev/sda3 - For /var partition
 - /dev/sda5 - For /var/exports partition, which is huge, but contains mostly no critical data for me

 
Now i mostly use combination of DD and Bzip2 to create an drive image, along with PV to see actual copying progress.
I wanted to automatize this process but with one exception - on /dev/sda5 just tar some folders instead of creating whole partition image.

This script may be useful for others, since it is very easy and have very minimal dependencies

Configuration
-------------------------
Configuration is done by few commented variables at the beginning of the script.

