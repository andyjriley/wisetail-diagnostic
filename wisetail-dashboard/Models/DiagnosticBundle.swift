//
//  DiagnosticBundle.swift
//  wisetail-dashboard
//
//  Top-level model holding parsed diagnostic data from a .wldiag bundle.
//  Only lightweight metadata is loaded at import time. Heavy data (logs,
//  database entities, API logs, service files) is loaded on-demand from
//  the persistent unzipped directory.
//

import Foundation

/// Metadata about a single log file discovered in the bundle.
struct LogFileInfo: Identifiable, Hashable {
    let id: String  // filename
    let filename: String
    let date: String         // e.g. "2026-02-11"
    let type: LogFileType    // .app or .push
    let sizeBytes: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

enum LogFileType: String, CaseIterable, Identifiable {
    case app = "App Log"
    case push = "Push Log"
    var id: String { rawValue }
}

/// Summary statistics computed from file-system metadata and lightweight
/// JSON decoding. Does NOT read log file contents.
struct BundleSummary {
    /// Individual log file metadata (date, type, size)
    let logFiles: [LogFileInfo]
    let apiCallCount: Int
    let apiErrorCount: Int
    let entityNames: [String]
    let entityRecordCounts: [String: Int]
    let syncStateCount: Int
    let serviceFileNames: [String]

    /// Unique dates across all log files, sorted descending (most recent first)
    var logDates: [String] {
        Array(Set(logFiles.map(\.date))).sorted().reversed()
    }

    /// Total size of all log files
    var logTotalBytes: Int64 {
        logFiles.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Human-readable total log size
    var formattedLogSize: String {
        ByteCountFormatter.string(fromByteCount: logTotalBytes, countStyle: .file)
    }
}

/// The diagnostic bundle. Heavy data is NOT loaded at init time—only the
/// manifest, device/sync/cache info, and summary counts.
/// The `rootDir` persists on disk until this object is deallocated.
final class DiagnosticBundle {
    let sourceURL: URL
    let rootDir: URL
    let manifest: ManifestInfo
    let deviceInfo: DeviceInfo?
    let syncInfo: SyncInfo?
    let cacheInfo: CacheInfo?
    let keychainInfo: KeychainData?
    let userDefaults: UserDefaultsData?
    let summary: BundleSummary

    init(
        sourceURL: URL,
        rootDir: URL,
        manifest: ManifestInfo,
        deviceInfo: DeviceInfo?,
        syncInfo: SyncInfo?,
        cacheInfo: CacheInfo?,
        keychainInfo: KeychainData?,
        userDefaults: UserDefaultsData?,
        summary: BundleSummary
    ) {
        self.sourceURL = sourceURL
        self.rootDir = rootDir
        self.manifest = manifest
        self.deviceInfo = deviceInfo
        self.syncInfo = syncInfo
        self.cacheInfo = cacheInfo
        self.keychainInfo = keychainInfo
        self.userDefaults = userDefaults
        self.summary = summary
    }

    deinit {
        print("[DiagnosticBundle] deinit — cleaning up temp directory: \(rootDir.lastPathComponent)")
        try? FileManager.default.removeItem(at: rootDir)
    }
}
