#!/bin/bash
set -euo pipefail

CONFIG="${1:-Release}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> Building PosterLab ($CONFIG)..."
rm -rf build/DerivedData build/Payload build/*.app build/*.ipa
mkdir -p build

xcodebuild -project PosterLab.xcodeproj \
    -scheme PosterLab \
    -configuration "$CONFIG" \
    -derivedDataPath build/DerivedData \
    -destination 'generic/platform=iOS' \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

APP_PATH="$(find build/DerivedData/Build/Products -name "PosterLab.app" -type d | head -n 1)"
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "Error: PosterLab.app not found in DerivedData"
    exit 1
fi

echo "==> Packaging IPA..."
cp -R "$APP_PATH" build/PosterLab.app

# Clean any existing signature
rm -rf build/PosterLab.app/_CodeSignature
rm -rf build/PosterLab.app/embedded.mobileprovision

mkdir -p build/Payload
cp -R build/PosterLab.app build/Payload/PosterLab.app

cd build
zip -qr "PosterLab.ipa" Payload
rm -rf Payload PosterLab.app

echo "==> Done! IPA generated at: $ROOT/build/PosterLab.ipa"
ls -lh "$ROOT/build/PosterLab.ipa"
