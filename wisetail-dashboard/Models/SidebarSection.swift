//
//  SidebarSection.swift
//  wisetail-dashboard
//
//  Sidebar navigation sections for the dashboard.
//

import Foundation

// MARK: - Sidebar Section

enum SidebarSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case logs = "Logs"
    case database = "Database"
    case syncTimeline = "Sync Timeline"
    case statistics = "Statistics"
    case deviceInfo = "Device Info"
    case userDefaults = "User Defaults"
    case keychain = "Keychain"
    case serviceFiles = "Service Files"
    case cacheInfo = "Cache"
    case aiAssistant = "AI Assistant"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .logs: return "doc.text"
        case .database: return "cylinder"
        case .syncTimeline: return "arrow.triangle.2.circlepath"
        case .statistics: return "chart.bar"
        case .deviceInfo: return "iphone"
        case .userDefaults: return "gearshape"
        case .keychain: return "key"
        case .serviceFiles: return "doc.on.doc"
        case .cacheInfo: return "internaldrive"
        case .aiAssistant: return "brain"
        }
    }

    /// Sections shown in the sidebar.
    static var diagnosticSections: [SidebarSection] {
        Array(allCases)
    }
}
