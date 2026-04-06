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

Release archives use **Hardened Runtime** and entitlements suitable for **Sparkle** auto-updates and **notarization**. When distributing outside the App Store, use **Developer ID** signing and follow Apple’s notarization workflow for the archived **Diagnostic Viewer** product.

## Using the app

- Use **File → Open Diagnostic Bundle…** (or **⌘O**) and choose a **`.wldiag`** file.
- The app unpacks the bundle and keeps a working folder for the session; use the sidebar to switch between inspectors.
- **Check for Updates…** (app menu) is provided if **Sparkle** is configured with a valid appcast and signed release artifacts.

## Sparkle (maintainers)

Update metadata lives under **`sparkle/appcast.xml`**. The app’s **`SUFeedURL`** in `wisetail-dashboard/Info.plist` points at the raw appcast URL on the default branch (adjust if the repo or branch name changes).

Shipping a new version typically involves: bump **Marketing Version** / **Build** in Xcode, archive with **Developer ID**, notarize, zip the `.app`, sign the archive with Sparkle’s **`sign_update`**, add an `<item>` to `appcast.xml` with the correct `edSignature` and `length`, create a **GitHub Release** with the same asset URL, and push the updated appcast.

## Project layout

| Path | Role |
|------|------|
| `wisetail-dashboard/` | App sources, assets, `Info.plist`, entitlements |
| `wisetail-dashboardTests/` | Unit tests |
| `wisetail-dashboardUITests/` | UI tests |
| `sparkle/` | Sparkle appcast (`appcast.xml`) |

## License

This work is released under the **CC0 1.0 Universal** license (`LICENSE`); you may use it for any purpose without asking for permission.

## Privacy note

Diagnostics can contain sensitive customer or device data. Treat **`.wldiag`** files and unpacked working directories like confidential material. The **AI Assistant** uses **on-device** Apple Intelligence to process the context you load; it does not require embedding third-party API keys for that feature in this project.
