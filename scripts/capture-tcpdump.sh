#!/bin/sh

# Capture packets on time-limited files

# binaries needed, change accordingly
TCPDUMP="/usr/sbin/tcpdump"
TCP_SPLIT="/usr/local/bin/tcpdump-split"
IFCONFIG="/sbin/ifconfig"
NTPDATE="/usr/sbin/ntpdate"

# Interface to capture packets
# **CHANGE THIS** accordingly
IFACE=eth0

# ** Interval **
# This value defines the amount of seconds each pcap file will contain.
# We suggest 10-minutes files (600 seconds), but you can change it if you
# receive a lot of traffic
INTERVAL=600

# Start and Stop time
# The collection process will work within this time-window.  If the
# start_time is in the future, will sleep until it's time to work.
# The collection won't go beyond STOP_T if it's given.
#
# NOTE: The start and stop times are interpreted as UTC.  Do not
# convert them to your local time zone.
#
#START_T='2010-04-13 13:00:00'
#STOP_T='2010-04-16 00:00:00'

# Program to run to handle a file
# Each time a INTERVAL is completed, will execute this program
# If this command uses arguments, include them later
KICK_CMD="./pcap-submit-to-oarc.sh"

# Unique name of the node where data is being collected.
# Please make sure that no two instances of tcpdump use the
# same NODENAME!
if [ `uname` = "Linux" ]; then
    NODENAME=`hostname --fqdn` 
else
    NODENAME=`hostname`
fi

# You can set SAVEDIR to a directory with lots of free space
# where the pcap files will be staged or stored
SAVEDIR="."


#
# End of configurable options
#

# Read local definitions if there is any
if [ -s settings.sh ]; then
    . ./settings.sh
fi

# if IFACES was given in settings.sh, stupidly convert it
# to what we hope is a single interface
if [ -n "$IFACES" ] ; then
	IFACE=$IFACES
fi

# Prepares the BPF_FILTER according to the settings given
# Queries only?
if [ "${QUERIES_ONLY}" = "yes" ]; then
    echo "Capturing queries only"
    BPF_FILTER="dst port 53"
else
    echo "Capturing queries and responses"
    BPF_FILTER="port 53"
fi

if [ "${DO_FRAGS}" = "yes" ]; then
    BPF_FILTER="$BPF_FILTER or ip[6:2]&0x1fff!=0 or ip6[6]=44"
fi

# Destinations?
if [ ! -z ${DESTINATIONS} ]; then
	if [ "${QUERIES_ONLY}" = "yes" ]; then
	    DST_FILTER=$(perl -e 'map { push(@D, "dst host $_"); } @ARGV; print join(" or ",@D);' ${DESTINATIONS})
	else
	    DST_FILTER=$(perl -e 'map { push(@D, "host $_"); } @ARGV; print join(" or ",@D);' ${DESTINATIONS})
	fi

    BPF_FILTER="($DST_FILTER) and ($BPF_FILTER)"
fi


# TCPdump options
TCPDUMP_OPTS="-s 0 -n -w - -i ${IFACE}"
if [ ! -z "${BPF_FILTER}" ]; then
	BPF_FILTER_FILE="/tmp/bpf_filter_$$.txt"
	echo ${BPF_FILTER} > ${BPF_FILTER_FILE}
	TCPDUMP_OPTS="${TCPDUMP_OPTS} -F ${BPF_FILTER_FILE}"
fi

# TCPsplit options
OUTFILE_FORMAT="${NODENAME}.%s.pcap"
set -- -t "${INTERVAL}" -f "${SAVEDIR}/${OUTFILE_FORMAT}"
if [ ! -z "${START_T}" ]; then
    set -- "$@" -B "${START_T}"
fi
if [ ! -z "${STOP_T}" ]; then
    set -- "$@" -E "${STOP_T}"
fi
if [ ! -z "${KICK_CMD}" ]; then
    set -- "$@" -k "${KICK_CMD}"
fi

# Validate the programs I'm expecting to use
for prog in ${TCPDUMP} ${TCP_SPLIT} ${IFCONFIG} ${NTPDATE} ${KICK_CMD}; do
if [ ! -x ${prog} ] ; then
    echo "${prog} is not executable, aborting!"
    exit 1
fi
done

# Check if this script is running as root
if test -z "$UID" ; then
	UID=`id -u`
fi
if [ "${UID}" != "0" ]; then
    echo "Must run as root!"
    exit 1
fi
echo "Passed running-as-root check"

# Validate some of the input parameters
# Is IFACE a valid interface
IFACE_CHECK=`${IFCONFIG} ${IFACE}`
if [ $? != "0" ]; then
    echo "Interface ${IFACE} checking failed!"
    echo "${IFACE_CHECK}"
    exit 1
fi
echo "Passed ifconfig checks"

# NTP Check
# Verifies if the clocks are properly synchronized
NTP_CHECK=`${NTPDATE} -q pool.ntp.org`
if [ $? != "0" ]; then
    echo "NTP check failed!"
    echo $NTP_CHECK
    exit 1
fi
# Now verify if offset is lower than certain threshold
NTP_OFFSET=`echo $NTP_CHECK | grep offset | head -1 | cut -d, -f3 | cut -d' ' -f3`
# Shell don't do float arithmetic, so we use bc for comparison
OFFSET_THRESHOLD="0.5"
if [ $(echo "${NTP_OFFSET} > ${OFFSET_THRESHOLD}" | bc) -eq 1 ]; then
    echo "Your clock is skewed by ${NTP_OFFSET} seconds!"
    echo "We suggest a clock sync, Aborting"
    exit 1
fi
echo "Passed NTP Check"

# Check INTERVAL is a number
echo $INTERVAL | egrep '^[0-9]+$' >/dev/null 2>&1
if [ $? != "0" ]; then
    echo "The interval ${INTERVAL} given is not a number, aborting"
    exit 1
fi


CMD="${TCPDUMP} ${TCPDUMP_OPTS} | ${TCP_SPLIT} $@"
echo "Executing '${CMD}'"
${TCPDUMP} ${TCPDUMP_OPTS} | ${TCP_SPLIT} "$@"

# Some cleaning up
rm -f ${BPF_FILTER_FILE}
