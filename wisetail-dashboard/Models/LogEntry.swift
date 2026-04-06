//
//  LogEntry.swift
//  wisetail-dashboard
//

import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let rawText: String
    let timestamp: Date?
    let level: LogLevel?
    let category: String?
    let message: String
}

enum LogLevel: String, CaseIterable, Identifiable {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case notice = "NOTICE"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .verbose: return 0
        case .debug: return 1
        case .info: return 2
        case .notice: return 3
        case .warning: return 4
        case .error: return 5
        case .critical: return 6
        }
    }
}
