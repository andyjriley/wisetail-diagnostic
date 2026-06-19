#!/usr/bin/env bash
# Build, package, sign, and optionally notarize a Sparkle release archive.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="wisetail-dashboard"
CONFIGURATION="Release"
STAGING="/tmp/diagnostic-viewer-release-staging"
SIGN_KEY="${ROOT}/sparkle/sparkle-signing-private.key"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <marketing-version>   e.g. 1.0.0" >&2
  exit 1
fi

ZIP_NAME="Diagnostic-Viewer-${VERSION}.zip"
OUT_ZIP="${ROOT}/sparkle/${ZIP_NAME}"

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo "ERROR: No 'Developer ID Application' signing identity found." >&2
  echo "Create one in Apple Developer → Certificates, download in Xcode, then rebuild." >&2
  echo "Apps signed with 'Apple Development' cannot be distributed outside Xcode." >&2
  exit 1
fi

SIGN_UPDATE="$(find ~/Library/Developer/Xcode/DerivedData -path '*/artifacts/sparkle/Sparkle/bin/sign_update' 2>/dev/null | head -1)"
if [[ -z "$SIGN_UPDATE" ]]; then
  echo "ERROR: Sparkle sign_update not found. Build the project in Xcode once first." >&2
  exit 1
fi

echo "==> Building ${SCHEME} (${CONFIGURATION}) with Developer ID…"
xcodebuild \
  -project "${ROOT}/wisetail-dashboard.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  build

APP="$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/${CONFIGURATION}/Diagnostic Viewer.app" 2>/dev/null | head -1)"
if [[ ! -d "$APP" ]]; then
  echo "ERROR: Built app not found." >&2
  exit 1
fi

echo "==> Verifying code signature…"
codesign --verify --deep --strict "$APP"

echo "==> Staging clean copy (no resource forks)…"
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto --norsrc "$APP" "${STAGING}/Diagnostic Viewer.app"
codesign --verify --deep --strict "${STAGING}/Diagnostic Viewer.app"

echo "==> Creating zip (preserves symlinks, no AppleDouble files)…"
rm -f "$OUT_ZIP"
(
  cd "$STAGING"
  COPYFILE_DISABLE=1 zip -r -y -X "$OUT_ZIP" "Diagnostic Viewer.app"
)

echo "==> Verifying zip extracts with valid signature…"
VERIFY_DIR="/tmp/diagnostic-viewer-release-verify"
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
(
  cd "$VERIFY_DIR"
  unzip -q "$OUT_ZIP"
  codesign --verify --deep --strict "Diagnostic Viewer.app"
)

if [[ ! -f "$SIGN_KEY" ]]; then
  echo "WARN: ${SIGN_KEY} not found; skipping Sparkle archive signature." >&2
else
  echo "==> Sparkle archive signature (add to appcast enclosure):"
  "$SIGN_UPDATE" --ed-key-file "$SIGN_KEY" "$OUT_ZIP"
fi

echo ""
echo "Next steps:"
echo "  1. Notarize: xcrun notarytool submit '$OUT_ZIP' --keychain-profile AC_PASSWORD --wait"
echo "  2. Staple the app inside the zip is not possible; notarize the .app before zipping, or use a .dmg."
echo "     Recommended: notarize/staple the .app, then re-run packaging from the stapled app."
echo "  3. Upload ${ZIP_NAME} to the GitHub Release for v${VERSION}."
echo "  4. Update sparkle/appcast.xml with edSignature and length, then push."
