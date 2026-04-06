//
//  DiagnosticTools.swift
//  wisetail-dashboard
//
//  Tool-conforming types that the Foundation Models framework can invoke
//  on-demand to fetch specific data from the diagnostic bundle.
//

import Foundation
import FoundationModels

// MARK: - Data Provider Protocol

@MainActor
protocol DiagnosticDataProvider: AnyObject, Sendable {
    var logEntries: [LogEntry]? { get }
    var syncStates: SyncStatesData? { get }
    var apiLogs: APILogsData? { get }
    var bundle: DiagnosticBundle? { get }
}

extension DashboardViewModel: DiagnosticDataProvider {}

// MARK: - Search Logs Tool

final class SearchLogsTool: Tool {
    let name = "searchLogs"
    let description = "Searches loaded log entries for a keyword or phrase and returns matching lines (up to 50 results)."

    @Generable
    struct Arguments {
        @Guide(description: "The search keyword or phrase to look for in log messages.")
        let query: String
    }

    let dataProvider: any DiagnosticDataProvider

    init(dataProvider: any DiagnosticDataProvider) {
        self.dataProvider = dataProvider
    }

    nonisolated func call(arguments: Arguments) async throws -> String {
        let queryLower = arguments.query.lowercased()
        return await MainActor.run {
            guard let logs = dataProvider.logEntries else {
                return "No log entries are currently loaded. The user needs to visit the Logs tab first to load a log file."
            }

            let matches = logs.filter { $0.message.lowercased().contains(queryLower) || $0.rawText.lowercased().contains(queryLower) }
            let capped = Array(matches.prefix(50))

            if capped.isEmpty {
                return "No log entries matched '\(arguments.query)'."
            }

            let lines = capped.map { entry in
                "[\(entry.level?.rawValue ?? "?")] [\(entry.category ?? "?")] \(entry.message)"
            }
            return "Found \(matches.count) matches (showing \(capped.count)):\n" + lines.joined(separator: "\n")
        }
    }
}

// MARK: - Get Recent Errors Tool

final class GetRecentErrorsTool: Tool {
    let name = "getRecentErrors"
    let description = "Returns the most recent error-level and critical-level log entries from the loaded logs."

    @Generable
    struct Arguments {
        @Guide(description: "Maximum number of error entries to return.", .range(1...100))
        let count: Int
    }

    let dataProvider: any DiagnosticDataProvider

    init(dataProvider: any DiagnosticDataProvider) {
        self.dataProvider = dataProvider
    }

    nonisolated func call(arguments: Arguments) async throws -> String {
        let maxCount = arguments.count
        return await MainActor.run {
            guard let logs = dataProvider.logEntries else {
                return "No log entries are currently loaded. The user needs to visit the Logs tab first to load a log file."
            }

            let errors = logs.filter { $0.level == .error || $0.level == .critical }
            let recent = Array(errors.suffix(maxCount))

            if recent.isEmpty {
                return "No error or critical log entries found in the currently loaded logs."
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let lines = recent.map { entry in
                let ts = entry.timestamp.map { formatter.string(from: $0) } ?? "?"
                return "[\(ts)] [\(entry.level?.rawValue ?? "?")] [\(entry.category ?? "?")] \(entry.message)"
            }
            return "\(errors.count) total errors. Showing \(recent.count) most recent:\n" + lines.joined(separator: "\n")
        }
    }
}

// MARK: - Get Sync States Tool

final class GetSyncStatesTool: Tool {
    let name = "getSyncStates"
    let description = "Returns sync state records with dates, statuses, and failure reasons from the diagnostic bundle."

    @Generable
    struct Arguments {
        @Guide(description: "Placeholder, not used.")
        let unused: String?
    }

    let dataProvider: any DiagnosticDataProvider

    init(dataProvider: any DiagnosticDataProvider) {
        self.dataProvider = dataProvider
    }

    nonisolated func call(arguments: Arguments) async throws -> String {
        return await MainActor.run {
            guard let data = dataProvider.syncStates else {
                return "Sync state data has not been loaded yet. The user needs to visit the Sync Timeline tab first."
            }

            if data.records.isEmpty {
                return "No sync state records found in the bundle."
            }

            let lines = data.records.prefix(30).map { r in
                var parts: [String] = []
                parts.append("Route: \(r.apiRoute ?? "N/A")")
                parts.append("User: \(r.userId ?? "N/A")")
                if let start = r.fullSyncStartDate {
                    parts.append("Full Sync: \(start) → \(r.fullSyncEndDate.map(String.init(describing:)) ?? "in progress") [\(r.fullSyncStatus ?? "?")]")
                }
                if let start = r.partialSyncStartDate {
                    parts.append("Partial Sync: \(start) → \(r.partialSyncEndDate.map(String.init(describing:)) ?? "in progress") [\(r.partialSyncStatus ?? "?")]")
                }
                if let fail = r.lastFailureStartDate {
                    parts.append("FAILURE: \(fail) - \(r.lastFailureReason ?? "unknown reason")")
                }
                return parts.joined(separator: " | ")
            }
            return "\(data.records.count) sync state records (showing \(min(30, data.records.count))):\n" + lines.joined(separator: "\n")
        }
    }
}

// MARK: - Get API Errors Tool

final class GetAPIErrorsTool: Tool {
    let name = "getAPIErrors"
    let description = "Returns API log records that have errors, including the route, status code, and error message."

    @Generable
    struct Arguments {
        @Guide(description: "Placeholder, not used.")
        let unused: String?
    }

    let dataProvider: any DiagnosticDataProvider

    init(dataProvider: any DiagnosticDataProvider) {
        self.dataProvider = dataProvider
    }

    nonisolated func call(arguments: Arguments) async throws -> String {
        return await MainActor.run {
            guard let data = dataProvider.apiLogs else {
                return "API log data has not been loaded yet. The user needs to visit the Sync Timeline tab first."
            }

            let errors = data.records.filter { $0.isError }
            if errors.isEmpty {
                return "No API errors found in the recorded API logs."
            }

            let lines = errors.prefix(50).map { r in
                let url = r.url ?? "?"
                let method = r.method ?? "?"
                let status = r.errorStatusCode.map(String.init) ?? r.statusCode.map(String.init) ?? "?"
                let msg = r.errorMessage ?? r.errorReason ?? "unknown"
                let date = r.errorDate.map(String.init(describing:)) ?? "?"
                return "[\(date)] \(method) \(url) → \(status): \(msg)"
            }
            return "\(errors.count) API errors (showing \(min(50, errors.count))):\n" + lines.joined(separator: "\n")
        }
    }
}
