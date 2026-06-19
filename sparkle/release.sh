#!/usr/bin/env bash
# Archive, export with Developer ID, notarize, package, and sign a Sparkle release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="wisetail-dashboard"
TEAM_ID="WSAL3K955T"
ARCHIVE_PATH="/tmp/DiagnosticViewer.xcarchive"
EXPORT_PATH="/tmp/DiagnosticViewer-export"
STAGING="/tmp/diagnostic-viewer-release-staging"
EXPORT_PLIST="${ROOT}/sparkle/ExportOptions.plist"
SIGN_KEY="${ROOT}/sparkle/sparkle-signing-private.key"
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_PASSWORD}"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <marketing-version>   e.g. 1.0.0" >&2
  exit 1
fi

ZIP_NAME="Diagnostic-Viewer-${VERSION}.zip"
OUT_ZIP="${ROOT}/sparkle/${ZIP_NAME}"

SIGN_UPDATE="$(find ~/Library/Developer/Xcode/DerivedData -path '*/artifacts/sparkle/Sparkle/bin/sign_update' 2>/dev/null | head -1)"
if [[ -z "$SIGN_UPDATE" ]]; then
  echo "ERROR: Sparkle sign_update not found. Build the project in Xcode once first." >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo "ERROR: No Developer ID Application identity in Keychain." >&2
  echo "" >&2
  echo "Your Apple team (${TEAM_ID}) also needs cloud distribution certificate access." >&2
  echo "In Xcode: Settings → Accounts → your team → Manage Certificates → + → Developer ID Application" >&2
  echo "If that fails, ask your team's Account Holder to grant distribution certificate access," >&2
  echo "or create a Developer ID Application cert at developer.apple.com and download it." >&2
  exit 1
fi

echo "==> Archiving ${SCHEME}…"
xcodebuild \
  -project "${ROOT}/wisetail-dashboard.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  -allowProvisioningUpdates

echo "==> Exporting with Developer ID…"
rm -rf "$EXPORT_PATH"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates

APP="${EXPORT_PATH}/Diagnostic Viewer.app"
codesign --verify --deep --strict "$APP"

echo "==> Notarizing app (zip for notarytool)…"
NOTARY_ZIP="/tmp/DiagnosticViewer-notary.zip"
rm -f "$NOTARY_ZIP"
ditto -c -k --keepParent "$APP" "$NOTARY_ZIP"

if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
  xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  codesign --verify --deep --strict "$APP"
  spctl -a -vv "$APP"
else
  echo "WARN: notarytool profile '${NOTARY_PROFILE}' not found; skipping notarization." >&2
  echo "      Store credentials: xcrun notarytool store-credentials ${NOTARY_PROFILE}" >&2
  echo "      Gatekeeper will still block downloads until the app is notarized." >&2
fi

echo "==> Staging clean copy…"
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto --norsrc "$APP" "${STAGING}/Diagnostic Viewer.app"
codesign --verify --deep --strict "${STAGING}/Diagnostic Viewer.app"

echo "==> Creating distribution zip…"
rm -f "$OUT_ZIP"
(
  cd "$STAGING"
  COPYFILE_DISABLE=1 zip -r -y -X "$OUT_ZIP" "Diagnostic Viewer.app"
)

VERIFY_DIR="/tmp/diagnostic-viewer-release-verify"
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
(
  cd "$VERIFY_DIR"
  unzip -q "$OUT_ZIP"
  codesign --verify --deep --strict "Diagnostic Viewer.app"
)

if [[ -f "$SIGN_KEY" ]]; then
  echo "==> Sparkle archive signature (add to appcast enclosure):"
  "$SIGN_UPDATE" --ed-key-file "$SIGN_KEY" "$OUT_ZIP"
else
  echo "WARN: ${SIGN_KEY} not found; skipping Sparkle archive signature." >&2
fi

echo ""
echo "Release archive: ${OUT_ZIP}"
echo "Upload ${ZIP_NAME} to GitHub Release v${VERSION}, update sparkle/appcast.xml, and push."
