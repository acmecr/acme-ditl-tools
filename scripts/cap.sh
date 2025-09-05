#!/bin/bash

. ./.env

# std tcpdump 

while true ; do 
	
	FILENAME="capture_$(date +"%Y%m%d%H%M%Si").pcap"; 

	# 50 megabytes = roughly 50 million bytes(weird tcpdump standard) 
	# change user to root cos of some problem where it cant read the var
	tcpdump -i enp4s0 -W 1 -w $CAPTURE_DIR/$FILENAME -C 2 -G 2 -Z root -v &
	TCPDUMP_PID=$!

	echo "$TCPDUMP_PID" 
	
	sleep 600 # 30 mins
	kill $TCPDUMP_PID >/dev/null 2>&1

	$MINIO_BIN_DIR/mc cp $CAPTURE_DIR/$FILENAME minio/sidnlabs-iceberg-data/pcap-in/ ; 
	rm $CAPTURE_DIR/$FILENAME;
	sleep 1
done
