#!/usr/bin/env bash

# docs/logo.svg is the canonical Coppelia app-icon source. Run this after any
# visual change so every checked-in platform and store asset stays in sync.
set -euo pipefail

SOURCE='docs/logo.svg'
IOS='ios/Runner/Assets.xcassets/AppIcon.appiconset'
MAC='macos/Runner/Assets.xcassets/AppIcon.appiconset'
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/coppelia-logo.XXXXXX")
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing canonical logo source: $SOURCE" >&2
  exit 1
fi

if ! command -v qlmanage >/dev/null || ! command -v sips >/dev/null; then
  echo 'This generator requires macOS qlmanage and sips.' >&2
  exit 1
fi

qlmanage -t -s 4096 -o "$TEMP_DIR" "$SOURCE" >/dev/null
INPUT="$TEMP_DIR/$(basename "$SOURCE").png"

if [[ ! -f "$INPUT" ]]; then
  echo "Quick Look did not render $SOURCE" >&2
  exit 1
fi

copy_svg() {
  cp "$SOURCE" "$1"
}

resize_png() {
  sips -z "$1" "$1" "$INPUT" --out "$2" >/dev/null
}

copy_svg assets/logo.svg
copy_svg assets/logo_app_icon.svg
copy_svg website/assets/logo.svg
cp "$INPUT" assets/logo.png
cp "$INPUT" fastlane/metadata/android/en-US/images/icon.png

mkdir -p android/app/src/main/res/drawable-nodpi

while IFS=: read -r size file; do
  resize_png "$size" "android/app/src/main/res/$file"
done <<'EOF'
48:mipmap-mdpi/ic_launcher.png
72:mipmap-hdpi/ic_launcher.png
96:mipmap-xhdpi/ic_launcher.png
144:mipmap-xxhdpi/ic_launcher.png
192:mipmap-xxxhdpi/ic_launcher.png
432:drawable-nodpi/ic_launcher_adaptive_foreground.png
EOF

while IFS=: read -r size file; do
  resize_png "$size" "$IOS/$file"
done <<'EOF'
20:Icon-App-20x20@1x.png
40:Icon-App-20x20@2x.png
60:Icon-App-20x20@3x.png
29:Icon-App-29x29@1x.png
58:Icon-App-29x29@2x.png
87:Icon-App-29x29@3x.png
40:Icon-App-40x40@1x.png
80:Icon-App-40x40@2x.png
120:Icon-App-40x40@3x.png
76:Icon-App-76x76@1x.png
152:Icon-App-76x76@2x.png
167:Icon-App-83.5x83.5@2x.png
120:Icon-App-60x60@2x.png
180:Icon-App-60x60@3x.png
1024:Icon-App-1024x1024@1x.png
16:app_icon_16.png
32:app_icon_32.png
64:app_icon_64.png
128:app_icon_128.png
256:app_icon_256.png
512:app_icon_512.png
1024:app_icon_1024.png
EOF

while IFS=: read -r size file; do
  resize_png "$size" "$MAC/$file"
done <<'EOF'
16:app_icon_16.png
32:app_icon_32.png
64:app_icon_64.png
128:app_icon_128.png
256:app_icon_256.png
512:app_icon_512.png
1024:app_icon_1024.png
EOF
