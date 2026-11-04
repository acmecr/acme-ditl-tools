#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

#
# ----- defaults -------
# (shd be overwritten by settings.sh)
#
DNSCAP="/usr/bin/dnscap"

IFACES="ens18"
DESTINATIONS=""

QUERIES_ONLY="no"
DO_TCP="yes"
DO_FRAGS="yes"

INTERVAL="600"

START_T=""
STOP_T=""

CHRONY_MAX_CORRECTION="0.5"
CHRONY_TRIES="6"
CHRONY_CHECK_INTERVAL="2"

KICK_CMD=""

if [ "$(uname)" = "Linux" ]; then
    NODENAME=$(hostname --fqdn 2>/dev/null || hostname)
else
    NODENAME=$(hostname)
fi

SAVEDIR="/tmp"

#
# ------- preflight checks -------
#

# 
# (this check just to make sure configs is loaded from the right place (relative to script)
if [ -s "$SCRIPT_DIR/settings.sh" ]; then
    . "$SCRIPT_DIR/settings.sh"
fi

#
# root test
if [ "$(id -u)" -ne 0 ]; then
    echo "running as root:\tFAIL"
    echo "!! ERROR: scripts must run as root"
    exit 1
fi
echo "running as root:\tok!"
echo ""

#
# test mostly for retrocompatibility
if [ ! -x "$DNSCAP" ]; then
    echo "dnscap okay:\tFAIL"
    echo "!! ERROR: dnscap not executable: $DNSCAP"
    exit 1
fi
echo "dnscap okay:\tyes im ok!"
echo ""

#
# interface check
if [ -z "$IFACES" ]; then
    echo "!! ERROR: no interface set!"
    exit 1
fi

#
# chrony present
if ! command -v chronyc >/dev/null 2>&1; then
    echo "chrony installed:\tFAIL"
    echo "!! ERROR: chronyc not found"
    exit 1
fi
echo "chrony installed:\tok!"
echo ""

#
# chrony sync test
if ! chronyc waitsync \
    "$CHRONY_TRIES" \
    "$CHRONY_MAX_CORRECTION" \
    0 \
    "$CHRONY_CHECK_INTERVAL"
then
    echo "chrony sync:\tFAIL"
    echo "!! ERROR: chrony not synchronized within ${CHRONY_MAX_CORRECTION}s"
    exit 1
fi
echo "chrony sync:\tok!"
echo ""

#
# validate output dir 
if [ ! -d "$SAVEDIR" ]; then
    echo "output dir okay:\tFAIL not ok!!!"
    echo "!! ERROR: capture directory DOES NOT EXIST: $SAVEDIR"
    exit 1
fi

if [ ! -w "$SAVEDIR" ]; then
    echo "output dir okay:\tFAIL not ok!!!"
    echo "!! ERROR: capture directory NOT WRITABLE: $SAVEDIR"
    exit 1
fi

echo "output dir okay:\tyes im ok!"
echo ""

#
# interval validation
case "$INTERVAL" in
    ''|*[!0-9]*)
	echo "interval validation:\tFAIL"
        echo "!! ERROR: INTERVAL must be an integer! current: $INTERVAL"
        exit 1
        ;;
esac
echo "interval validation:\tok!"

#
# ------- dnscap command assembly -------
#

#
# argument reference:
# ---
#
# qun		(query, update, notify)
#
# -e ny 	(keep normal AND error responses)
#
# ---
#

set -- \
    -N \
    -t "$INTERVAL" \
    -w "$SAVEDIR/$NODENAME" \
    -m qun \
    -e ny


if [ -n "$START_T" ]; then
    set -- "$@" -B "$START_T"
fi

if [ -n "$STOP_T" ]; then
    set -- "$@" -E "$STOP_T"
fi

if [ -n "$KICK_CMD" ]; then
    if [ ! -x "$KICK_CMD" ]; then
        echo "!! ERROR: KICK_CMD not executable!\t $KICK_CMD"
        exit 1
    fi

    set -- "$@" -k "$KICK_CMD"
fi

#
# validate/add interfaces
for IFACE in $IFACES; do
    if [ ! -d "/sys/class/net/$IFACE" ]; then
        echo "!! ERROR: interface $IFACE not found"
        exit 1
    fi

    echo ""
    echo "-------"
    echo " capturing interface:\t $IFACE"
    set -- "$@" -i "$IFACE"
done

#
# destination filtering (optional)
if [ -n "$DESTINATIONS" ]; then
    for DEST in $DESTINATIONS; do
        set -- "$@" -z "$DEST"
    done
fi

if [ "$QUERIES_ONLY" = "yes" ]; then
    echo " queries/responses:\t !! QUERIES ONLY !!"
    echo ""

    set -- "$@" -s i
else
    echo " queries/responses:\t QUERIES AND RESPONSES"
fi

if [ "$DO_TCP" = "yes" ]; then
    echo " TCP DNS:\t CAPTURING TCP DNS"
    set -- "$@" -T
else
    echo " TCP DNS:\t NOT CAPTURING TCP DNS"
fi


if [ "$DO_FRAGS" = "yes" ]; then
    echo "IP fragments:\t !! CAPTRUING IP FRAGMENTS"
    set -- "$@" -f
else
    echo "IP FRAGMENTS:\t !! NOT CAPTURING IP FRAGMENTS"
fi

echo "-------"
echo ""

echo ""
echo " full capture command:"
echo ""
printf '%s ' "$DNSCAP" "$@"
echo ""
echo ""

exec "$DNSCAP" "$@"
