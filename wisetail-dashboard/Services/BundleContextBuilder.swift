//
//  BundleContextBuilder.swift
//  wisetail-dashboard
//
//  Builds a structured text summary of the diagnostic bundle for the
//  AI session's system instructions. Keeps within a reasonable token
//  budget by including only key metadata.
//

import Foundation

struct BundleContextBuilder {

    /// Builds a context string from the diagnostic bundle and any loaded data.
    static func buildContext(from bundle: DiagnosticBundle, viewModel: DashboardViewModel) -> String {
        var sections: [String] = []

        // Manifest
        let m = bundle.manifest
        sections.append("""
        BUNDLE MANIFEST:
        - Export Date: \(m.exportDate)
        - Device: \(m.deviceName) (\(m.deviceModel))
        - Device ID: \(m.deviceId)
        - iOS Version: \(m.iosVersion)
        - App Version: \(m.appVersion) (\(m.appBuild))
        """)

        // Device Info
        if let d = bundle.deviceInfo {
            sections.append("""
            DEVICE INFO:
            - Approval State: \(d.approvalState)
            - Device Mode: \(d.deviceMode)
            - Mode Initialized: \(d.modeInitialized)
            - Network Reachable: \(d.networkReachable), WiFi: \(d.wifiReachable), Cellular: \(d.cellularReachable)
            - Battery: \(d.batteryLevel)% (\(d.batteryState))
            - Disk: \(ByteCountFormatter.string(fromByteCount: d.freeDiskSpaceBytes, countStyle: .file)) free of \(ByteCountFormatter.string(fromByteCount: d.totalDiskSpaceBytes, countStyle: .file))
            - Company: \(d.companyName ?? "N/A")
            - Base URL: \(d.baseUrl ?? "N/A")
            - FCM Token Present: \(d.fcmToken != nil)
            - Last Notification: \(d.lastNotificationReceived ?? "None")
            """)
        }

        // Sync Info
        if let s = bundle.syncInfo {
            sections.append("""
            SYNC INFO:
            - Last Full Sync: \(s.lastFullSyncStart.map(String.init(describing:)) ?? "N/A") → \(s.lastFullSyncEnd.map(String.init(describing:)) ?? "N/A")
            - Last Partial Sync: \(s.lastPartialSyncStart.map(String.init(describing:)) ?? "N/A") → \(s.lastPartialSyncEnd.map(String.init(describing:)) ?? "N/A")
            - Last Failure: \(s.lastFailureDate.map(String.init(describing:)) ?? "None")
            - Failure Reason: \(s.lastFailureReason ?? "None")
            - Background Sync Enabled: \(s.backgroundSyncEnabled)
            - Background Refresh Status: \(s.backgroundRefreshStatus)
            - Sync Interval: \(s.syncInterval ?? "N/A")
            """)
        }

        // Cache Info
        if let c = bundle.cacheInfo {
            let pct = String(format: "%.1f%%", c.utilizationPercentage)
            sections.append("""
            CACHE INFO:
            - Size: \(ByteCountFormatter.string(fromByteCount: c.currentCacheSizeBytes, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: c.cacheLimitBytes, countStyle: .file)) (\(pct))
            - Cached Files: \(c.totalCachedFiles)
            - Deferred Downloads: \(c.deferredDownloadCount) (\(ByteCountFormatter.string(fromByteCount: c.deferredDownloadSizeBytes, countStyle: .file)))
            - Auto-Fill: \(c.autoFillEnabled), WiFi Only: \(c.wifiOnlyEnabled)
            """)
        }

        // Summary stats
        let sum = bundle.summary
        sections.append("""
        BUNDLE SUMMARY:
        - Log Files: \(sum.logFiles.count) files, \(sum.formattedLogSize) total
        - Log Dates: \(sum.logDates.joined(separator: ", "))
        - API Calls Recorded: \(sum.apiCallCount) (\(sum.apiErrorCount) errors)
        - Database Entities: \(sum.entityNames.joined(separator: ", "))
        - Entity Record Counts: \(sum.entityRecordCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        - Sync State Records: \(sum.syncStateCount)
        - Service Files: \(sum.serviceFileNames.joined(separator: ", "))
        """)

        // Log file details
        if !sum.logFiles.isEmpty {
            let logDetails = sum.logFiles.map { "  - \($0.filename) [\($0.type.rawValue)] \($0.formattedSize)" }
            sections.append("LOG FILES:\n" + logDetails.joined(separator: "\n"))
        }

        // If logs are already loaded, include error/warning summary
        if let logs = viewModel.logEntries {
            let errorCount = logs.filter { $0.level == .error || $0.level == .critical }.count
            let warningCount = logs.filter { $0.level == .warning }.count
            sections.append("""
            LOADED LOG ANALYSIS:
            - Total Entries: \(logs.count)
            - Errors: \(errorCount)
            - Warnings: \(warningCount)
            """)
        }

        return sections.joined(separator: "\n\n")
    }
}
