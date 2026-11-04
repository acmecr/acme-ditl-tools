#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)


if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root!" >&2
    exit 1
fi


if [ ! -s "$SCRIPT_DIR/settings.sh" ]; then
    echo "ERROR: settings.sh not found" >&2
    exit 1
fi


. "$SCRIPT_DIR/settings.sh"

: "${MC:?MC not configured!}"
: "${MC_ALIAS:?MC_ALIAS not configured!}"
: "${MC_ENDPOINT:?MC_ENDPOINT not configured!}"
: "${MC_ACCESS_KEY:?MC_ACCESS_KEY not set!}"
: "${MC_SECRET_KEY:?MC_SECRET_KEY not set!}"


if [ ! -x "$MC" ]; then
    echo "ERROR: mc is not executable: $MC" >&2
    exit 1
fi


echo "---------"

echo "configuring minio alias '$MC_ALIAS' for root..."

if "$MC" alias set \
    "$MC_ALIAS" \
    "$MC_ENDPOINT" \
    "$MC_ACCESS_KEY" \
    "$MC_SECRET_KEY"
then
    echo "success!"
    echo ""
    echo "alias '$MC_ALIAS' configured successfully."
else
	echo "ERROR: failed to configure alias '$MC_ALIAS'. (uploads will fail!!!)" >&2
    exit 1
fi

if ! "$MC" ls "$REMOTE" >/dev/null 2>&1; then
    echo "?! WARN: alias defined, but CANNOT ACCESS ENDPOINT $REMOTE" >&2
    echo "!! WARN: collection will start, uploads will remain locally" >&2
    
fi

echo ""
echo "minio endpoint setup complete!"
echo ""

echo "       summary:"
echo "------------------------"

echo " alias:\t $MC_ALIAS"

echo " endpoint:\t $MC_ENDPOINT"

echo "   - endpoint preview: "
"$MC" tree -d 4 "$MC_ALIAS" || echo " !! ERROR: command `mc tree` failed !"
# echo " $($MC tree -d 4 $MC_ALIAS)"

echo "------------------------"
echo ""
