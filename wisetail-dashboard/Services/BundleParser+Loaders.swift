//
//  BundleParser+Loaders.swift
//  wisetail-dashboard
//
//  On-demand data loaders that read heavy content from the unzipped
//  bundle directory. Called by DashboardViewModel when the user
//  navigates to the corresponding tab.
//

import Foundation

extension BundleParser {

    // MARK: - Log File

    /// Parses a single log file from the bundle's logs/ directory.
    static func loadLogFile(rootDir: URL, filename: String) -> [LogEntry] {
        let logsDir = rootDir.appendingPathComponent("logs")
        let logURL = logsDir.appendingPathComponent(filename)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: logURL.path)[.size] as? Int64) ?? 0
        print("[BundleParser:Logs] Loading \(filename) (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))...")
        let start = CFAbsoluteTimeGetCurrent()

        guard let content = try? String(contentsOf: logURL, encoding: .utf8) else {
            print("[BundleParser:Logs] Failed to read file")
            return []
        }

        let entries = LogParser.parse(content: content)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("[BundleParser:Logs] Parsed \(entries.count) entries in \(String(format: "%.2f", elapsed))s")
        return entries
    }

    // MARK: - Database Entities

    /// Decodes database/entities.json.
    static func loadDatabaseEntities(rootDir: URL) -> DatabaseEntities? {
        let url = rootDir.appendingPathComponent("database").appendingPathComponent("entities.json")
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        print("[BundleParser:DB] Loading entities.json (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))...")
        let start = CFAbsoluteTimeGetCurrent()
        let result: DatabaseEntities? = try? decodeJSONFile(url)
        print("[BundleParser:DB] Entities decoded in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - start))s — \(result?.entities.count ?? 0) entity types")
        return result
    }

    // MARK: - API Logs

    /// Decodes database/api_logs.json.
    static func loadAPILogs(rootDir: URL) -> APILogsData? {
        let url = rootDir.appendingPathComponent("database").appendingPathComponent("api_logs.json")
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        print("[BundleParser:API] Loading api_logs.json (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))...")
        let start = CFAbsoluteTimeGetCurrent()
        let result: APILogsData? = try? decodeJSONFile(url)
        print("[BundleParser:API] API logs decoded in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - start))s — \(result?.records.count ?? 0) records")
        return result
    }

    // MARK: - Sync States

    /// Decodes database/sync_states.json.
    static func loadSyncStates(rootDir: URL) -> SyncStatesData? {
        let url = rootDir.appendingPathComponent("database").appendingPathComponent("sync_states.json")
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        print("[BundleParser:Sync] Loading sync_states.json (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))...")
        let start = CFAbsoluteTimeGetCurrent()
        let result: SyncStatesData? = try? decodeJSONFile(url)
        print("[BundleParser:Sync] Sync states decoded in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - start))s — \(result?.records.count ?? 0) records")
        return result
    }

    // MARK: - Service Files

    /// Lists service file names (without reading content).
    static func listServiceFiles(rootDir: URL) -> [String] {
        let serviceDir = rootDir.appendingPathComponent("service_files")
        guard FileManager.default.fileExists(atPath: serviceDir.path) else { return [] }
        return (try? FileManager.default.contentsOfDirectory(atPath: serviceDir.path))?.sorted() ?? []
    }

    /// Reads a single service file's content from disk.
    static func loadServiceFile(rootDir: URL, name: String) -> String? {
        let fileURL = rootDir.appendingPathComponent("service_files").appendingPathComponent(name)
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
}
