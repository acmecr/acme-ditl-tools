#!/bin/sh

# This file contains local settings for capture-tcpdump.sh and
# capture-dnscap.sh scripts.  Rename it to settings.sh and customize.
# See capture-tcpdump.sh or capture-dnscap.sh for explanations of each
# variable.

. ./.env

# Settings that you should customize
#
IFACES=$INTERFACE
NODENAME=$SERVER_NAME
OARC_MEMBER="unesp"
QUERIES_ONLY="no"

# Leave these commented for dry runs and uncomment them for
# the actual DITL data collection.  NOTE, times must be
# given in UTC!
#

#START_T='2024-04-09 11:00:00'
#STOP_T='2024-04-11 13:00:00'

# Settings that you probably wont need to change
#
#SSH_ID="/root/.ssh/acme_unesp"
RM_AFTER_UPLOAD="yes"
#DESTINATIONS=""
#DO_TCP="yes"
#DO_V6="yes"
#DO_FRAGS="yes"
DNSCAP="/usr/local/bin/dnscap"
#TCPDUMP="/usr/sbin/tcpdump"
#IFCONFIG="/sbin/ifconfig"
#NTPDATE="/usr/sbin/ntpd"
#SSH_BIN="/usr/bin/ssh"
#TCP_SPLIT="/usr/local/bin/tcpdump-split"
SAVEDIR=$CAPTURE_DIR

# Settings that you shouldn't change
#
INTERVAL=$TIME_INTERVAL
KICK_CMD=$KICK_CMD
