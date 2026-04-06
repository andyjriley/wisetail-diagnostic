//
//  LogLevelChart.swift
//  wisetail-dashboard
//
//  Bar chart showing log entry counts per level.
//

import SwiftUI
import Charts

struct LogLevelChart: View {
    let entries: [LogEntry]

    var body: some View {
        GroupBox("Log Level Distribution") {
            if !entries.isEmpty {
                let levelCounts = Dictionary(grouping: entries.compactMap(\.level)) { $0 }
                    .mapValues(\.count)
                    .sorted { $0.key.sortOrder < $1.key.sortOrder }

                Chart(levelCounts, id: \.key) { level, count in
                    BarMark(
                        x: .value("Level", level.rawValue),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(colorForLevel(level))
                }
                .frame(height: 200)
                .padding()
            } else {
                Text("No log data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .verbose: return .gray
        case .debug: return .secondary
        case .info: return .blue
        case .notice: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
