#!/bin/sh

# This script is designed to be called as the -k command to
# the dnscap and tcpdump-split programs.
#
# Note: it sort of assumes that files can be uploaded at least
# as fast as they are generated.  If uploading is too slow you
# will end up with multiple pcap-submit-to-oarc.sh scripts
# running simultaneously.

. ./.env

OARC_MEMBER=
NODENAME=

RM_AFTER_UPLOAD="yes"
#SSH_ID=/root/.ssh/oarc_id_dsa
#SSH_BIN=/usr/bin/ssh
LOGGER="logger"

# Read local definitions if there is any
# You can use this file to set your own values without modifying this
# script
if [ -s settings.sh ]; then
    . ./settings.sh
fi

: ${OARC_MEMBER:?}
: ${NODENAME:?}

REMOTE=minio/sidnlabs-iceberg-data/pcap-in/
calc_md5()
{
	case "`uname -s`" in
	Linux)
                MY_MD5=`/usr/bin/md5sum $1 | awk '{print $1}'`
                return $?
		;;
	OpenBSD)
                MY_MD5=`/bin/md5 $1 | awk '{print $NF}'`
                return $?
		;;
	FreeBSD)
                MY_MD5=`/sbin/md5 -q $1`
                return $?
		;;
	*)
		if test -f /sbin/md5 ; then
			MY_MD5=`/sbin/md5 -q $1`
			return $?
		elif test -f /usr/bin/md5sum ; then
			MY_MD5=`/usr/bin/md5sum $1 | awk '{print $1}'`
			return $?
		fi
		echo "Cannot calculate MD5 for $1" |$LOGGER
		return 1
		;;
        esac
}

ls -l $1 |$LOGGER
if expr $1 : '.*\.gz$' >/dev/null; then
	set `basename $1 .gz`
else
	gzip -9v $1 2>&1 |$LOGGER
	ls -l $1.gz |$LOGGER
fi
calc_md5 $1.gz || exit 1
echo "Sending $1.gz with MD5 $MY_MD5 to OARC" |$LOGGER

output=$($MINIO_BIN_DIR/mc cp $1.gz $REMOTE)
rm $1.gz 2>&1 |$LOGGER

#if [ $? -eq 0 ]; then
#        echo "$SSH_BIN completed successfully" |$LOGGER
#        if [ "$output" = "MD5 $MY_MD5" ]; then
#                echo "Remote and local MD5s match for $1.gz" |$LOGGER#
#		if test $RM_AFTER_UPLOAD = "yes" ; then
#			echo "removing $1.gz" |$LOGGER
#                	rm $1.gz 2>&1 |$LOGGER
#		fi
#        else
#                echo "Remote MD5 ($output) does not match local MD5 ($MY_MD5)" |$LOGGER
#        fi
#fi

exit 0
