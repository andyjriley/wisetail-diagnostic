//
//  SyncDurationChart.swift
//  wisetail-dashboard
//
//  Horizontal bar chart of full-sync durations per route.
//

import SwiftUI
import Charts

struct SyncDurationChart: View {
    let records: [SyncStateRecord]

    var body: some View {
        GroupBox("Sync Duration Summary") {
            if !records.isEmpty {
                let durations = records.compactMap { record -> (String, Double)? in
                    guard let start = record.fullSyncStartDate,
                          let end = record.fullSyncEndDate else { return nil }
                    return (record.apiRoute ?? "Unknown", end.timeIntervalSince(start))
                }

                if !durations.isEmpty {
                    Chart(durations, id: \.0) { route, duration in
                        BarMark(
                            x: .value("Duration (s)", duration),
                            y: .value("Route", route)
                        )
                        .foregroundStyle(.teal.gradient)
                    }
                    .frame(height: max(200, CGFloat(durations.count) * 30))
                    .padding()
                } else {
                    Text("No sync duration data available")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            } else {
                Text("No sync state data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}
