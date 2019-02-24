#!/bin/bash

# Path were images should be placed, should be your backup drive
SAVE_PATH='/var/backup/'

# Put here drives which you want to backup
DRIVES=(sda1 root sda4)
# This array is name map of image file, so sda1=bootfs.tar.gz, root=rootfs.tar.gz etc...
DRIVES_NAMES=("bootfs" "rootfs" "varfs")

# Put here folders which you want to backup additionally
DIRS=(/var/exports/git /var/exports/photos)
# Simillar to drives, this array is name map of image file, so /var/backup/git=git.tar.gz etc...
DIRS_NAMES=("git" "photos")

# Set to 1, if you want to get
SEND_FINISH_MAIL=1
EMAIL_SENDER='your_ssmtp_sending_mail@example.com'
EMAIL_RECEPIENT='your_mail@example.com'
EMAIL_SUBJECT='['`uname -n`'] Backup Completed!'

CUR_DATE=`date +%d%m%y`
LOG_FILE=$SAVE_PATH'backup-'$CUR_DATE'.log'
SUM_FILE=$SAVE_PATH'backup-'$CUR_DATE'.md5'
EMAIL_TMP_FILE='/tmp/backupFinishMail'

log() {
	local str="["`date`"] "$1
	echo $str
	echo $str >> $LOG_FILE
}

packDirs() {
	local filepath=$SAVE_PATH$1'-'$CUR_DATE'.tar.bz2'
	local dirSize=`du -sb $2 | awk '{print $1}'`
	log "Packing directory "$2" to "$filepath
	tar cf - $2 | pv -s $dirSize | bzip2 -9f > $filepath
	local compressedSize=`du -sb $filepath | awk '{print $1}'`
	log "Compressed...Size was "$(($dirSize / 1024 / 1024))"MB now is "$(($compressedSize / 1024 / 1024))"MB"
	log "Testing integrity of file "$filepath
	if ! bzip2 -tv $filepath; then
		log "File "$filepath" is not OK!"
	else
		log "File "$filepath" is OK! Creating MD5SUM..."
		md5sum $filepath >> $SUM_FILE
	fi
}

createDriveImg() {
	local drive_id=${DRIVES[$1]}
	local drive_name=${DRIVES_NAMES[$1]}
	local drive_size=`df -k -B 1 | grep $drive_id | head -n 1 | awk '{print $2}'`
	local img_path=$SAVE_PATH$drive_name'-'$CUR_DATE'.img.bz2'
	log "Working on "$drive_id" which is "$drive_name" size is "$drive_size" bytes. Saving to "$img_path
	dd if=/dev/$drive_id | pv -s $drive_size |  bzip2 -9f > $img_path
	local compressedSize=`du -sb $img_path | awk '{print $1}'`
	log "Compressed...Size was "$(( $drive_size / 1024 / 1024))"MB now is "$(($compressedSize / 1024 / 1024))"MB"
	log "Testing integrity of file "$img_path
	if ! bzip2 -tv $img_path; then
                log "File "$img_path" is not OK!"
        else
                log "File "$img_path" is OK! Creating MD5SUM..."
                md5sum $img_path >> $SUM_FILE
        fi
}

sendFinishMail() {
	echo "To: "$EMAIL_RECEPIENT > $EMAIL_TMP_FILE
	echo "From: "$EMAIL_SENDER >> $EMAIL_TMP_FILE
	echo "Subject: "$EMAIL_SUBJECT >> $EMAIL_TMP_FILE
	echo "" >> $EMAIL_TMP_FILE
	echo "" >> $EMAIL_TMP_FILE
	cat $LOG_FILE >> $EMAIL_TMP_FILE
	ssmtp $EMAIL_RECEPIENT < $EMAIL_TMP_FILE
	rm -f $EMAIL_TMP_FILE
}


# Main script starts here...

if ! [ "$TERM" = "screen" ];
then
    	echo "WARNING: Not running under screen!"
fi

if grep -qs '/dev/sda1' /proc/mounts; then
    log "BootFS mounted...Good!"
else
    log "BootFS not mounted...Mounting..."
    mount /boot
fi

rm -f $SUM_FILE

for dir in ${!DIRS[@]}
do
	dir_path=${DIRS[$dir]}
        dir_name=${DIRS_NAMES[$dir]}
	packDirs $dir_name $dir_path
done

for drive in ${!DRIVES[@]}
do
	createDriveImg $drive
done

if ! md5sum -c $SUM_FILE; then
	log "Files are NOT OK!"
else
	log "Files are OK!"
fi

if [ "$SEND_FINISH_MAIL" -ne "0" ]; then
	log "Sending mail..."
	sendFinishMail
fi

