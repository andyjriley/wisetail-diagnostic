# wisetail-diagnostic

**WiseLync Diagnostic Viewer** is a macOS SwiftUI app for opening WiseLync **`.wldiag`** diagnostic bundles. It unzips a bundle to a working directory, parses manifests and metadata, and lets you explore logs, database exports, sync state, charts, and device details. An optional **AI Assistant** uses **Apple Intelligence** (on-device) to help interpret the loaded diagnostic context.

Repository: [github.com/andyjriley/wisetail-diagnostic](https://github.com/andyjriley/wisetail-diagnostic)

## Features

| Area | What you can do |
|------|------------------|
| **Overview** | Quick summary of the bundle and entry points into other sections |
| **Logs** | Browse log files (app vs push), filter, and inspect parsed entries |
| **Database** | Explore exported entities and records from the bundle |
| **Sync Timeline** | Visual timeline of sync-related events |
| **Statistics** | Charts for API traffic, durations, status codes, log levels/categories, etc. |
| **Device Info** | Hardware / OS / app metadata from the diagnostic |
| **User Defaults** | Inspect exported defaults-style key–value data |
| **Keychain** | Review keychain-related payload (where present in the bundle) |
| **Service Files** | Browse ancillary service files included in the bundle |
| **Cache** | Cache summary and related metadata |
| **AI Assistant** | Chat with an on-device model using context built from the open bundle (see requirements below) |

Heavy data (full log bodies, large DB slices) is loaded **on demand** when you open a section, so importing a bundle stays responsive.

## Requirements

- **macOS 26** or later (matches the project’s deployment target).
- **Xcode 26** (or the SDK version your branch targets) to build from source.
- **Apple Intelligence** (Apple Silicon, model downloaded, enabled in System Settings) if you want to use the **AI Assistant**. The rest of the app works without it.

## Building and running

1. Clone the repository.
2. Open **`wisetail-dashboard.xcodeproj`** in Xcode.
3. Select the **`wisetail-dashboard`** scheme and a **My Mac** destination.
4. Run (**⌘R**).

Unit and UI test targets are included (`wisetail-dashboardTests`, `wisetail-dashboardUITests`).

### Distribution builds

Release builds are **Developer ID–signed**, **notarized**, and packaged for Sparkle. See [Shipping a new version](#shipping-a-new-version-maintainers) for the full release checklist.

## Using the app

- Use **File → Open Diagnostic Bundle…** (or **⌘O**) and choose a **`.wldiag`** file.
- The app unpacks the bundle and keeps a working folder for the session; use the sidebar to switch between inspectors.
- **Check for Updates…** (app menu) is provided if **Sparkle** is configured with a valid appcast and signed release artifacts.

## Sparkle (maintainers)

Update metadata lives under **`sparkle/appcast.xml`**. The app’s **`SUFeedURL`** in `wisetail-dashboard/Info.plist` points at the raw appcast on `main`:

`https://raw.githubusercontent.com/andyjriley/wisetail-diagnostic/main/sparkle/appcast.xml`

### One-time setup

Before your first release, confirm:

| Requirement | How |
|-------------|-----|
| **Apple team** | Xcode → target **wisetail-dashboard** → Signing & Capabilities → Team (`V97S9BNJWU`). `DEVELOPMENT_TEAM` and `sparkle/ExportOptions.plist` must match. |
| **Developer ID signing** | Xcode → Settings → Accounts → your team → **Manage Certificates** → **+** → **Developer ID Application** (or use cloud signing if your role allows it). |
| **App Store Connect access** | [Users and Access](https://appstoreconnect.apple.com/access/users) → your account → **Access to Certificates, Identifiers & Profiles** and **Access to Cloud Managed Distribution Certificate** enabled. |
| **Notarization credentials** | `xcrun notarytool store-credentials AC_PASSWORD` (app-specific password from [appleid.apple.com](https://appleid.apple.com)). Override with `NOTARY_PROFILE` if you use a different profile name. |
| **Sparkle EdDSA key** | `sparkle/sparkle-signing-private.key` on disk (gitignored). Public key is in `wisetail-dashboard/Info.plist` as `SUPublicEDKey`. Generate with Sparkle’s `generate_keys` if needed. |

If export fails with **“Cloud signing permission error”**, your Apple ID lacks distribution certificate access on the team. As Account Holder/Admin, enable the permissions above or create a **Developer ID Application** certificate at [developer.apple.com](https://developer.apple.com/account/resources/certificates/list).

Never commit `sparkle/sparkle-signing-private.key`, `*.p8` API keys, or release `*.zip` archives.

### Shipping a new version

Example: releasing **1.1.0** (build **2**).

#### 1. Bump version in Xcode

- Open **`wisetail-dashboard`** target → **General**.
- Increase **Version** (`MARKETING_VERSION`, e.g. `1.1.0`) and **Build** (`CURRENT_PROJECT_VERSION`, e.g. `2`).
- **`sparkle:version`** in the appcast must match **Build** (integer). **`sparkle:shortVersionString`** must match **Version**.

Commit the version bump on `main`.

#### 2. Build, notarize, and sign the archive

Build the project in Xcode once so Sparkle’s `sign_update` tool is available, then:

```bash
sparkle/release.sh 1.1.0
```

This script archives, exports with **Developer ID**, submits to Apple for **notarization**, staples the ticket, creates a clean zip at `sparkle/Diagnostic-Viewer-1.1.0.zip`, and prints Sparkle `edSignature` and `length` values. Wait for `spctl` to report **accepted** / **Notarized Developer ID**.

#### 3. Add a GitHub Release

1. Create release tag **`v1.1.0`** on `main` (GitHub → Releases → **Draft a new release**).
2. Upload **`sparkle/Diagnostic-Viewer-1.1.0.zip`** as a release asset. The file name must match the appcast URL.
3. Asset URL pattern: `https://github.com/andyjriley/wisetail-diagnostic/releases/download/v1.1.0/Diagnostic-Viewer-1.1.0.zip`

#### 4. Update the appcast

Add a new `<item>` **above** older items in `sparkle/appcast.xml` (newest first):

```xml
<item>
	<title>1.1.0</title>
	<pubDate>Thu, 19 Jun 2026 00:00:00 +0000</pubDate>
	<sparkle:version>2</sparkle:version>
	<sparkle:shortVersionString>1.1.0</sparkle:shortVersionString>
	<sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
	<sparkle:releaseNotesLink>https://github.com/andyjriley/wisetail-diagnostic/releases/tag/v1.1.0</sparkle:releaseNotesLink>
	<enclosure
		url="https://github.com/andyjriley/wisetail-diagnostic/releases/download/v1.1.0/Diagnostic-Viewer-1.1.0.zip"
		sparkle:edSignature="PASTE_FROM_sign_update_OUTPUT"
		length="PASTE_BYTE_SIZE_FROM_sign_update_OUTPUT"
		type="application/octet-stream"
	/>
</item>
```

Use the exact `edSignature` and `length` from `release.sh` output for **that zip file**. Do not use `sparkle:installationType` for `.app` zip updates (only `package` for archived `.pkg` inside a zip).

#### 5. Push the appcast

```bash
git add sparkle/appcast.xml
git commit -m "Release v1.1.0"
git push origin main
```

Sparkle clients read the appcast from `main`; the GitHub Release hosts the binary. Both must be live before **Check for Updates…** will offer the new version.

#### 6. Smoke test

1. Install an older build (or the previous release).
2. **Check for Updates…** from the app menu.
3. Confirm download, install, and relaunch.
4. Optionally verify a fresh download from the GitHub Release opens without Gatekeeper warnings:

```bash
spctl -a -vv "Diagnostic Viewer.app"
# expected: accepted, source=Notarized Developer ID
```

### Replacing a release asset

If you must re-upload the same version (e.g. fixed signing), replace the asset on the GitHub Release, re-run `release.sh` for that version, update `edSignature` and `length` in the appcast (they change with the new zip), and push. Sparkle rejects archives whose signature does not match the downloaded file byte-for-byte.

## Project layout

| Path | Role |
|------|------|
| `wisetail-dashboard/` | App sources, assets, `Info.plist`, entitlements |
| `wisetail-dashboardTests/` | Unit tests |
| `wisetail-dashboardUITests/` | UI tests |
| `sparkle/` | Sparkle appcast (`appcast.xml`), `release.sh`, `ExportOptions.plist` |

## License

This work is released under the **CC0 1.0 Universal** license (`LICENSE`); you may use it for any purpose without asking for permission.

## Privacy note

Diagnostics can contain sensitive customer or device data. Treat **`.wldiag`** files and unpacked working directories like confidential material. The **AI Assistant** uses **on-device** Apple Intelligence to process the context you load; it does not require embedding third-party API keys for that feature in this project.
