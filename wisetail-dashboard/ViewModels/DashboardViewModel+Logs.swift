//
//  DashboardViewModel+Logs.swift
//  wisetail-dashboard
//
//  Log file selection, per-file loading, and log filtering logic.
//

import Foundation

extension DashboardViewModel {

    // MARK: - Log Computed Properties

    var logFiles: [LogFileInfo] { bundle?.summary.logFiles ?? [] }
    var logTotalSize: String { bundle?.summary.formattedLogSize ?? "0 bytes" }

    var logLineCount: Int? { logEntries?.count }
    var errorLogCount: Int? {
        logEntries?.filter { $0.level == .error || $0.level == .critical }.count
    }
    var warningLogCount: Int? {
        logEntries?.filter { $0.level == .warning }.count
    }

    /// Available dates for log filtering
    var logDates: [String] { bundle?.summary.logDates ?? [] }

    /// Available log types for the selected date
    var logTypesForSelectedDate: [LogFileType] {
        guard let date = selectedLogDate else { return [] }
        return logFiles.filter { $0.date == date }.map(\.type).sorted { $0.rawValue < $1.rawValue }
    }

    /// The LogFileInfo for the currently selected date + type
    var selectedLogFileInfo: LogFileInfo? {
        guard let date = selectedLogDate else { return nil }
        return logFiles.first { $0.date == date && $0.type == selectedLogType }
    }

    var logCategories: [String] {
        guard let entries = logEntries else { return [] }
        return Set(entries.compactMap(\.category)).sorted()
    }

    var filteredLogEntries: [LogEntry] {
        guard let entries = logEntries else { return [] }
        var filtered = entries

        if let level = selectedLogLevel {
            filtered = filtered.filter { $0.level == level }
        }
        if let category = selectedLogCategory {
            filtered = filtered.filter { $0.category == category }
        }
        if !logSearchText.isEmpty {
            filtered = filtered.filter {
                $0.rawText.localizedCaseInsensitiveContains(logSearchText)
            }
        }
        return filtered
    }

    // MARK: - Per-File Log Loading

    /// Called when selectedLogDate or selectedLogType changes.
    func loadSelectedLogFile() {
        guard let rootDir = bundle?.rootDir else { return }
        guard let fileInfo = selectedLogFileInfo else {
            logEntries = nil
            loadedLogFilename = nil
            return
        }

        // If this file is already loaded, skip
        if loadedLogFilename == fileInfo.filename { return }

        isLoadingLogFile = true
        logEntries = nil
        print("[ViewModel:Logs] Loading file: \(fileInfo.filename) (\(fileInfo.formattedSize))")

        Task { [weak self, filename = fileInfo.filename] in
            let entries = await Task.detached {
                BundleParser.loadLogFile(rootDir: rootDir, filename: filename)
            }.value
            guard let self else { return }
            print("[ViewModel:Logs] Assigning \(entries.count) log entries to UI")
            self.logEntries = entries
            self.loadedLogFilename = filename
            self.isLoadingLogFile = false
            print("[ViewModel:Logs] Done")
        }
    }
}
