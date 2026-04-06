//
//  SyncTimelineView.swift
//  wisetail-dashboard
//
//  Visual timeline of sync events, API calls, and failures.
//  TimelineEvent model is in Models/TimelineEvent.swift.
//

import SwiftUI

struct SyncTimelineView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var selectedEvent: TimelineEvent?

    private var isDataLoading: Bool {
        viewModel.sectionLoading.contains(.syncTimeline)
    }

    var body: some View {
        Group {
            if isDataLoading && viewModel.syncStates == nil && viewModel.apiLogs == nil {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text("Loading sync timeline...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    List(timelineEvents, selection: $selectedEvent) { event in
                        TimelineEventRow(event: event)
                            .tag(event)
                    }
                    .frame(minWidth: 300, idealWidth: 400)

                    TimelineEventDetail(event: selectedEvent)
                        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Event Computation

    private var timelineEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []

        if let syncStates = viewModel.syncStates?.records {
            for record in syncStates {
                if let start = record.fullSyncStartDate {
                    events.append(TimelineEvent(
                        date: start, endDate: record.fullSyncEndDate,
                        type: .fullSync, title: "Full Sync",
                        subtitle: record.apiRoute ?? "Unknown route",
                        status: record.fullSyncStatus ?? "unknown",
                        detail: "User: \(record.userId ?? "N/A")"
                    ))
                }
                if let start = record.partialSyncStartDate {
                    events.append(TimelineEvent(
                        date: start, endDate: record.partialSyncEndDate,
                        type: .partialSync, title: "Partial Sync",
                        subtitle: record.apiRoute ?? "Unknown route",
                        status: record.partialSyncStatus ?? "unknown",
                        detail: "User: \(record.userId ?? "N/A")"
                    ))
                }
                if let start = record.lastFailureStartDate {
                    events.append(TimelineEvent(
                        date: start, endDate: record.lastFailureEndDate,
                        type: .failure, title: "Sync Failure",
                        subtitle: record.lastFailureReason ?? "Unknown reason",
                        status: "failed", detail: record.apiRoute
                    ))
                }
            }
        }

        if let apiLogs = viewModel.apiLogs?.records.filter({ $0.isError }) {
            for log in apiLogs {
                if let ts = log.effectiveDate {
                    events.append(TimelineEvent(
                        date: ts, endDate: nil,
                        type: .apiError, title: "API Error",
                        subtitle: log.shortUrl, status: "error",
                        detail: log.errorMessage
                    ))
                }
            }
        }

        return events.sorted { $0.date > $1.date }
    }
}

// MARK: - Timeline Event Row

private struct TimelineEventRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.type.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(event.type.color)
                    Spacer()
                    Text(Self.dateFormatter.string(from: event.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(event.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let duration = event.duration {
                    Text(String(format: "Duration: %.1fs", duration))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()
}

// MARK: - Timeline Event Detail

private struct TimelineEventDetail: View {
    let event: TimelineEvent?

    var body: some View {
        if let event {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: event.type.icon)
                        .font(.title)
                        .foregroundStyle(event.type.color)
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Divider()

                Group {
                    InfoRow(label: "Type", value: event.type.rawValue)
                    InfoRow(label: "Status", value: event.status)
                    InfoRow(label: "Start", value: Self.fullDateFormatter.string(from: event.date))
                    if let end = event.endDate {
                        InfoRow(label: "End", value: Self.fullDateFormatter.string(from: end))
                    }
                    if let duration = event.duration {
                        InfoRow(label: "Duration", value: String(format: "%.2f seconds", duration))
                    }
                    InfoRow(label: "Details", value: event.subtitle)
                    if let detail = event.detail {
                        InfoRow(label: "Additional", value: detail)
                    }
                }

                Spacer()
            }
            .padding()
        } else {
            ContentUnavailableView(
                "Select an Event",
                systemImage: "clock",
                description: Text("Choose a timeline event to view details.")
            )
        }
    }

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .long
        return f
    }()
}
