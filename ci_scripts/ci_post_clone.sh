#!/bin/sh
set -e

# GoogleService-Info.plist is gitignored; Xcode Cloud rebuilds it from a
# secret environment variable (base64) defined in App Store Connect.
if [ -z "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "error: GOOGLE_SERVICE_INFO_PLIST environment variable is not set in Xcode Cloud."
    exit 1
fi

PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/VocabularyForest/GoogleService-Info.plist"
echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 -d > "$PLIST_PATH"
echo "GoogleService-Info.plist restored at $PLIST_PATH"
