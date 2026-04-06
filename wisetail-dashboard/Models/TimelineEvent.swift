//
//  TimelineEvent.swift
//  wisetail-dashboard
//
//  Model for sync timeline events displayed in SyncTimelineView.
//

import SwiftUI

struct TimelineEvent: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let endDate: Date?
    let type: EventType
    let title: String
    let subtitle: String
    let status: String
    let detail: String?

    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(date)
    }

    enum EventType: String, CaseIterable {
        case fullSync = "Full Sync"
        case partialSync = "Partial Sync"
        case failure = "Failure"
        case apiError = "API Error"

        var color: Color {
            switch self {
            case .fullSync: return .blue
            case .partialSync: return .cyan
            case .failure: return .red
            case .apiError: return .orange
            }
        }

        var icon: String {
            switch self {
            case .fullSync: return "arrow.triangle.2.circlepath.circle.fill"
            case .partialSync: return "arrow.triangle.2.circlepath"
            case .failure: return "xmark.circle.fill"
            case .apiError: return "exclamationmark.triangle.fill"
            }
        }
    }
}
