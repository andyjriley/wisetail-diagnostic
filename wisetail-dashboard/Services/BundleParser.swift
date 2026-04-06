//
//  BundleParser.swift
//  wisetail-dashboard
//
//  Unzips and parses .wldiag diagnostic bundle files.
//  Only lightweight metadata is parsed at import time.
//  Heavy data loaders are in BundleParser+Loaders.swift.
//

import Foundation

enum BundleParserError: LocalizedError {
    case invalidFile
    case unzipFailed(String)
    case missingManifest
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The selected file is not a valid diagnostic bundle."
        case .unzipFailed(let detail):
            return "Failed to unzip bundle: \(detail)"
        case .missingManifest:
            return "Bundle is missing manifest.json."
        case .decodingFailed(let detail):
            return "Failed to decode bundle data: \(detail)"
        }
    }
}

struct BundleParser {

    // MARK: - Initial Parse (lightweight)

    /// Unzips and parses only lightweight metadata from a .wldiag file.
    /// The unzipped directory persists on disk—heavy data is read on-demand.
    static func parse(url: URL) throws -> DiagnosticBundle {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent("wldiag-\(UUID().uuidString)")
        let startTime = CFAbsoluteTimeGetCurrent()

        print("[BundleParser] Starting parse for: \(url.lastPathComponent)")

        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        do {
            print("[BundleParser] Unzipping...")
            let unzipStart = CFAbsoluteTimeGetCurrent()
            try unzip(source: url, destination: tempDir)
            print("[BundleParser] Unzip completed in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - unzipStart))s")
        } catch {
            try? fm.removeItem(at: tempDir)
            throw error
        }

        let rootDir: URL
        do {
            rootDir = try findBundleRoot(in: tempDir)
            print("[BundleParser] Bundle root: \(rootDir.lastPathComponent)")
        } catch {
            try? fm.removeItem(at: tempDir)
            throw error
        }

        // Decode manifest (required)
        guard let manifestData = try? Data(contentsOf: rootDir.appendingPathComponent("manifest.json")) else {
            try? fm.removeItem(at: tempDir)
            throw BundleParserError.missingManifest
        }

        let manifest: ManifestInfo
        do {
            manifest = try decodeJSON(manifestData)
            print("[BundleParser] Manifest decoded OK: \(manifest.deviceName)")
        } catch {
            try? fm.removeItem(at: tempDir)
            throw BundleParserError.decodingFailed("manifest.json: \(error.localizedDescription)")
        }

        // Decode small optional sections
        print("[BundleParser] Decoding small JSON files...")
        let deviceInfo: DeviceInfo? = try? decodeJSONFile(rootDir.appendingPathComponent("device_info.json"))
        let syncInfo: SyncInfo? = try? decodeJSONFile(rootDir.appendingPathComponent("sync_info.json"))
        let cacheInfo: CacheInfo? = try? decodeJSONFile(rootDir.appendingPathComponent("cache_info.json"))
        let keychainInfo: KeychainData? = try? decodeJSONFile(rootDir.appendingPathComponent("keychain.json"))
        let userDefaults: UserDefaultsData? = try? decodeJSONFile(rootDir.appendingPathComponent("user_defaults.json"))

        // Compute summary stats without loading full content
        print("[BundleParser] Computing summary stats...")
        let summaryStart = CFAbsoluteTimeGetCurrent()
        let summary = computeSummary(rootDir: rootDir)
        print("[BundleParser] Summary computed in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - summaryStart))s")
        print("[BundleParser]   Log files: \(summary.logFiles.count), total size: \(summary.formattedLogSize)")
        print("[BundleParser]   Entities: \(summary.entityNames.count), API logs: \(summary.apiCallCount), Sync states: \(summary.syncStateCount)")

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("[BundleParser] Parse completed in \(String(format: "%.2f", totalTime))s")

        return DiagnosticBundle(
            sourceURL: url,
            rootDir: rootDir,
            manifest: manifest,
            deviceInfo: deviceInfo,
            syncInfo: syncInfo,
            cacheInfo: cacheInfo,
            keychainInfo: keychainInfo,
            userDefaults: userDefaults,
            summary: summary
        )
    }

    // MARK: - Summary

    /// Quickly scans files on disk to compute counts for the overview.
    /// Does NOT read log file contents—only uses file-system metadata.
    private static func computeSummary(rootDir: URL) -> BundleSummary {
        let fm = FileManager.default

        // Log files — extract date/type metadata from filenames
        var logFileInfos: [LogFileInfo] = []
        let logsDir = rootDir.appendingPathComponent("logs")
        if fm.fileExists(atPath: logsDir.path) {
            let logFiles = (try? fm.contentsOfDirectory(atPath: logsDir.path))?
                .filter { $0.hasSuffix(".log") }
                .sorted() ?? []
            for logFile in logFiles {
                let logURL = logsDir.appendingPathComponent(logFile)
                let size = (try? fm.attributesOfItem(atPath: logURL.path)[.size] as? Int64) ?? 0
                let baseName = logFile.replacingOccurrences(of: ".log", with: "")
                let parts = baseName.split(separator: "_", maxSplits: 1)
                let date = parts.count >= 1 ? String(parts[0]) : "unknown"
                let typeStr = parts.count >= 2 ? String(parts[1]) : "log"
                let fileType: LogFileType = typeStr.contains("push") ? .push : .app

                logFileInfos.append(LogFileInfo(
                    id: logFile, filename: logFile,
                    date: date, type: fileType, sizeBytes: size
                ))
            }
            let totalSize = logFileInfos.reduce(Int64(0)) { $0 + $1.sizeBytes }
            print("[BundleParser:Summary] Logs: \(logFileInfos.count) files, \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)) total")
        }

        // API log counts
        var apiCallCount = 0
        var apiErrorCount = 0
        let apiLogsURL = rootDir.appendingPathComponent("database/api_logs.json")
        if let data = try? Data(contentsOf: apiLogsURL) {
            struct Wrapper: Decodable { let records: [Record] }
            struct Record: Decodable { let isError: Bool }
            if let decoded = try? JSONDecoder().decode(Wrapper.self, from: data) {
                apiCallCount = decoded.records.count
                apiErrorCount = decoded.records.filter(\.isError).count
            }
        }

        // Entity names + record counts
        var entityNames: [String] = []
        var entityRecordCounts: [String: Int] = [:]
        let entitiesURL = rootDir.appendingPathComponent("database/entities.json")
        if let data = try? Data(contentsOf: entitiesURL) {
            struct Wrapper: Decodable {
                let entities: [String: [Stub]]
                struct Stub: Decodable {
                    init(from decoder: Decoder) throws { _ = try decoder.singleValueContainer() }
                }
            }
            if let decoded = try? JSONDecoder().decode(Wrapper.self, from: data) {
                entityNames = decoded.entities.keys.sorted()
                entityRecordCounts = decoded.entities.mapValues(\.count)
            }
        }

        // Sync state count
        var syncStateCount = 0
        let syncStatesURL = rootDir.appendingPathComponent("database/sync_states.json")
        if let data = try? Data(contentsOf: syncStatesURL) {
            struct Wrapper: Decodable {
                let records: [Stub]
                struct Stub: Decodable {
                    init(from decoder: Decoder) throws { _ = try decoder.singleValueContainer() }
                }
            }
            if let decoded = try? JSONDecoder().decode(Wrapper.self, from: data) {
                syncStateCount = decoded.records.count
            }
        }

        let serviceFileNames = listServiceFiles(rootDir: rootDir)

        return BundleSummary(
            logFiles: logFileInfos,
            apiCallCount: apiCallCount,
            apiErrorCount: apiErrorCount,
            entityNames: entityNames,
            entityRecordCounts: entityRecordCounts,
            syncStateCount: syncStateCount,
            serviceFileNames: serviceFileNames
        )
    }

    // MARK: - Private Helpers

    private static func unzip(source: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", source.path, destination.path]

        let pipe = Pipe()
        process.standardError = pipe
        try process.run()

        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw BundleParserError.unzipFailed(errorMsg)
        }
    }

    private static func findBundleRoot(in directory: URL) throws -> URL {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])

        if fm.fileExists(atPath: directory.appendingPathComponent("manifest.json").path) {
            return directory
        }

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                if fm.fileExists(atPath: item.appendingPathComponent("manifest.json").path) {
                    return item
                }
                let subContents = (try? fm.contentsOfDirectory(at: item, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
                for subItem in subContents {
                    let subIsDir = (try? subItem.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    if subIsDir && fm.fileExists(atPath: subItem.appendingPathComponent("manifest.json").path) {
                        return subItem
                    }
                }
            }
        }

        throw BundleParserError.missingManifest
    }

    static func decodeJSON<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    static func decodeJSONFile<T: Decodable>(_ url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decodeJSON(data)
    }
}
