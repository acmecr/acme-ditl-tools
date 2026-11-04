#!/bin/sh

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)


#
# ============ SETTNG LOADING AND VALIDATION ==========
#

# (defaults)
LOGGER="logger"
RM_AFTER_UPLOAD="no"
MC="/opt/acme-ditl-tools/minio-binaries/mc"
MC_ALIAS="minio"
REMOTE="minio/sidnlabs-iceberg-data/pcap-in/"

# get settings file:
#
if [ -s "$SCRIPT_DIR/settings.sh" ]; then
    . "$SCRIPT_DIR/settings.sh"
fi

# validation:
#
if [ "$#" -ne 1 ]; then
    echo "!! ERROR: invalid command! usage:\t $0 <pcap-file>" >&2
    exit 2
fi

FILE=$1

if [ ! -f "$FILE" ]; then
    echo "!! ERROR: file does not exist!\t $FILE" | "$LOGGER"
    exit 1
fi

if [ ! -x "$MC" ]; then
    echo "!! ERROR: mc not executable: $MC" | "$LOGGER"
    exit 1
fi

if ! "$MC" alias list "$MC_ALIAS" >/dev/null 2>&1; then
	echo "!! ERROR: mc endpoint alias '$MC_ALIAS' not configured for root!" | "$LOGGER"
    exit 1
fi

#
# ============ FILE UPLOAD TO ENDPOINT ==========
#

# compression if needed
case "$FILE" in
    *.gz)
        GZFILE="$FILE"
        ;;
    *)
        echo " compressing $FILE" | "$LOGGER"

        if ! gzip -9 -- "$FILE"; then
            echo "!! ERROR: gzip fail  $FILE" | "$LOGGER"
            exit 1
        fi

        GZFILE="$FILE.gz"
        ;;
esac

#
# upload
#
echo " . uploading $GZFILE to $REMOTE" | "$LOGGER"

if "$MC" cp "$GZFILE" "$REMOTE"; then
    echo "  sucess!\t\t  $GZFILE" | "$LOGGER"

    if [ "$RM_AFTER_UPLOAD" = "yes" ]; then
        echo "  removing local file\t\t  $GZFILE" | "$LOGGER"

        if ! rm -- "$GZFILE"; then
            echo "!! WARN: upload success, but LOCAL DELETION FAILED\t\t $GZFILE" \
                | "$LOGGER"
            exit 1
        fi
    else
        echo "  keeping local file\t\t  $GZFILE" | "$LOGGER"
    fi

    exit 0
else
    echo "!! ERROR: UPLOAD FAILED! KEEPING local file\t\t $GZFILE" | "$LOGGER"
    exit 1
fi
