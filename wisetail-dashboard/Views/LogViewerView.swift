//
//  LogViewerView.swift
//  wisetail-dashboard
//
//  Searchable, filterable log viewer. Loads one file at a time.
//  Sub-views: LogFileSelectionBar, LogFilterBar (in Components/).
//

import SwiftUI

struct LogViewerView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            LogFileSelectionBar()

            Divider()

            if viewModel.isLoadingLogFile {
                loadingIndicator
            } else if let entries = viewModel.logEntries, !entries.isEmpty {
                logContent
            } else if viewModel.selectedLogDate != nil {
                emptyState
            } else {
                ContentUnavailableView(
                    "Select a Date",
                    systemImage: "calendar",
                    description: Text("Choose a date and log type above to view log entries.")
                )
            }
        }
        .navigationTitle("Logs")
    }

    // MARK: - Sub-views

    private var loadingIndicator: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            if let info = viewModel.selectedLogFileInfo {
                Text("Loading \(info.filename)...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(info.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Loading log entries...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var logContent: some View {
        VStack(spacing: 0) {
            LogFilterBar()

            Divider()

            Table(viewModel.filteredLogEntries) {
                TableColumn("Line") { entry in
                    Text("\(entry.lineNumber)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .width(min: 40, ideal: 50, max: 60)

                TableColumn("Timestamp") { entry in
                    if let ts = entry.timestamp {
                        Text(Self.timestampFormatter.string(from: ts))
                            .font(.system(.caption, design: .monospaced))
                    } else {
                        Text("-").foregroundStyle(.tertiary)
                    }
                }
                .width(min: 140, ideal: 170, max: 200)

                TableColumn("Level") { entry in
                    if let level = entry.level {
                        LogLevelBadge(level: level)
                    }
                }
                .width(min: 70, ideal: 80, max: 100)

                TableColumn("Category") { entry in
                    if let cat = entry.category {
                        Text(cat)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 80, ideal: 100, max: 130)

                TableColumn("Message") { entry in
                    Text(entry.message)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.selectedLogFileInfo == nil {
            ContentUnavailableView(
                "No \(viewModel.selectedLogType.rawValue) for this date",
                systemImage: "doc.text",
                description: Text("Try selecting a different log type or date.")
            )
        } else {
            ContentUnavailableView(
                "No Log Entries",
                systemImage: "doc.text",
                description: Text("The selected log file is empty.")
            )
        }
    }

    // MARK: - Shared Formatter

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
}

// MARK: - Log Level Badge

struct LogLevelBadge: View {
    let level: LogLevel

    var body: some View {
        Text(level.rawValue)
            .font(.system(.caption, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var color: Color {
        switch level {
        case .verbose: return .gray
        case .debug: return .secondary
        case .info: return .blue
        case .notice: return .green
        case .warning: return .orange
        case .error, .critical: return .red
        }
    }
}
