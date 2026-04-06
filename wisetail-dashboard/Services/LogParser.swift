//
//  LogParser.swift
//  wisetail-dashboard
//
//  Parses plain-text PLogger log lines into structured LogEntry objects.
//
//  PLogger standard file format (from PLogEntryFormatter.standardFormatter):
//  "2025-01-15 10:23:45.123 ⚠️ [WARNING] [network] [SyncManager.swift->startSync:42] Some message"
//
//  PLogger short file format (from PLogEntryFormatter.shortFormatter):
//  "2025-01-15 10:23:45.123 ⚠️ [WARNING] [network] Some message"
//
//  Date format is always: yyyy-MM-dd HH:mm:ss.SSS (UTC)
//

import Foundation

struct LogParser {

    // Single date formatter matching PLogger's standardFormatter date output.
    // PLogDateFormatter.standardFormatter() uses "yyyy-MM-dd HH:mm:ss.SSS" in UTC.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    // Regex to extract timestamp at the start of a line: "2025-01-15 10:23:45.123"
    // Matches exactly the yyyy-MM-dd HH:mm:ss.SSS format.
    private static let timestampRegex = try! NSRegularExpression(
        pattern: #"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})"#,
        options: []
    )

    // Matches: [LEVEL] where LEVEL is one of the known PLogger log levels
    private static let levelPattern = try! NSRegularExpression(
        pattern: #"\[(VERBOSE|DEBUG|INFO|NOTICE|WARNING|ERROR|CRITICAL)\]"#,
        options: .caseInsensitive
    )

    // Matches: [category] - any bracketed word that isn't a level
    private static let categoryPattern = try! NSRegularExpression(
        pattern: #"\[([a-zA-Z_][a-zA-Z0-9_]*)\]"#,
        options: []
    )

    /// Parses a multi-line log file content into structured LogEntry objects.
    static func parse(content: String) -> [LogEntry] {
        var entries: [LogEntry] = []
        // Reserve capacity for efficiency (rough estimate: avg 100 chars per line)
        entries.reserveCapacity(content.count / 100)

        var lineNumber = 0
        content.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            lineNumber += 1
            let entry = parseLine(trimmed, lineNumber: lineNumber)
            entries.append(entry)
        }

        return entries
    }

    /// Parses a single log line into a LogEntry.
    static func parseLine(_ line: String, lineNumber: Int) -> LogEntry {
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        // 1. Extract timestamp efficiently using regex
        let timestamp = extractTimestamp(nsLine: nsLine, fullRange: fullRange)

        // 2. Extract log level
        let level = extractLevel(nsLine: nsLine, fullRange: fullRange)

        // 3. Extract category (first bracketed word that isn't a log level)
        let category = extractCategory(nsLine: nsLine, fullRange: fullRange, excludingLevel: level)

        // 4. Extract message (everything after the metadata)
        let message = extractMessage(from: line, timestamp: timestamp, level: level, category: category)

        return LogEntry(
            lineNumber: lineNumber,
            rawText: line,
            timestamp: timestamp,
            level: level,
            category: category,
            message: message
        )
    }

    // MARK: - Extraction helpers

    private static func extractTimestamp(nsLine: NSString, fullRange: NSRange) -> Date? {
        guard let match = timestampRegex.firstMatch(in: nsLine as String, options: [], range: fullRange) else {
            return nil
        }
        let dateString = nsLine.substring(with: match.range(at: 1))
        return dateFormatter.date(from: dateString)
    }

    private static func extractLevel(nsLine: NSString, fullRange: NSRange) -> LogLevel? {
        guard let match = levelPattern.firstMatch(in: nsLine as String, options: [], range: fullRange) else {
            return nil
        }
        let levelString = nsLine.substring(with: match.range(at: 1)).uppercased()
        return LogLevel(rawValue: levelString)
    }

    private static func extractCategory(nsLine: NSString, fullRange: NSRange, excludingLevel level: LogLevel?) -> String? {
        let matches = categoryPattern.matches(in: nsLine as String, options: [], range: fullRange)
        let levelStrings = Set(LogLevel.allCases.map { $0.rawValue.lowercased() })

        for match in matches {
            let category = nsLine.substring(with: match.range(at: 1))
            // Skip if this is actually a log level bracket
            if !levelStrings.contains(category.lowercased()) {
                return category
            }
        }
        return nil
    }

    private static func extractMessage(from line: String, timestamp: Date?, level: LogLevel?, category: String?) -> String {
        var msg = line

        // Remove timestamp portion (everything before the first [)
        if timestamp != nil {
            if let bracketIdx = msg.firstIndex(of: "[") {
                msg = String(msg[bracketIdx...])
            }
        }

        // Remove [LEVEL] tag
        if let level {
            msg = msg.replacingOccurrences(of: "[\(level.rawValue)]", with: "", options: .caseInsensitive)
        }

        // Remove [category] tag
        if let category {
            msg = msg.replacingOccurrences(of: "[\(category)]", with: "")
        }

        return msg.trimmingCharacters(in: .whitespaces)
    }
}
