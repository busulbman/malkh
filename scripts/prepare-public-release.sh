#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
if (( $# != 2 )); then print -u2 'Usage: scripts/prepare-public-release.sh VERSION BUILD'; exit 1; fi
if [[ ! "$1" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' || ! "$2" =~ '^[0-9]+$' ]]; then print -u2 'Use numeric release versions.'; exit 1; fi
export MALKH_APP_VERSION=$1 MALKH_BUILD_NUMBER=$2
export MALKH_UPDATE_CONFIG="$PWD/Configuration/Updates.public.plist"
export MALKH_APP_OUTPUT=${MALKH_APP_OUTPUT:-"$PWD/build/public-$1-$2/Malkh.app"}
feed_directory="$PWD/build/public-feed-$1-$2"
mkdir -p "$feed_directory"
archive="$feed_directory/Malkh-macOS-arm64-$1-$2.zip"
if [[ -e "$archive" ]]; then print -u2 'This release archive already exists. Keep it immutable and increment the version.'; exit 1; fi
scripts/build-app.sh release
python3 scripts/audit-release.py "$MALKH_APP_OUTPUT"
python3 scripts/archive-app.py "$MALKH_APP_OUTPUT" "$archive"
key_options=(--account "${MALKH_UPDATE_KEY_ACCOUNT:-com.busulbman.malkh}")
if [[ -n "${MALKH_UPDATE_KEY_FILE:-}" ]]; then key_options=(--ed-key-file "$MALKH_UPDATE_KEY_FILE"); fi
sparkle="$PWD/.build/artifacts/sparkle/Sparkle/bin"
prefix="https://github.com/busulbman/malkh/releases/download/v$1-$2/"
"$sparkle/generate_appcast" "${key_options[@]}" --download-url-prefix "$prefix" "$feed_directory"
"$sparkle/sign_update" "${key_options[@]}" --verify "$feed_directory/appcast.xml"
python3 scripts/validate-update-feed.py "$feed_directory/appcast.xml" "$2"
upload_directory="$PWD/build/public-upload-$1-$2"
mkdir -p "$upload_directory"
cp "$archive" "$upload_directory/${archive:t}"
cp "$archive" "$upload_directory/Malkh-macOS-arm64.zip"
cp "$feed_directory/appcast.xml" "$upload_directory/appcast.xml"
print "Signed public archive and feed: $feed_directory"
