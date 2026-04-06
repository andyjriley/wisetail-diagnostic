//
//  LogCategoryChart.swift
//  wisetail-dashboard
//
//  Horizontal bar chart showing top 15 log categories by count.
//

import SwiftUI
import Charts

struct LogCategoryChart: View {
    let entries: [LogEntry]

    var body: some View {
        GroupBox("Log Categories") {
            if !entries.isEmpty {
                let categoryCounts = Dictionary(grouping: entries.compactMap(\.category)) { $0 }
                    .mapValues(\.count)
                    .sorted { $0.value > $1.value }
                    .prefix(15)

                Chart(Array(categoryCounts), id: \.key) { category, count in
                    BarMark(
                        x: .value("Count", count),
                        y: .value("Category", category)
                    )
                    .foregroundStyle(.indigo.gradient)
                }
                .frame(height: max(200, CGFloat(categoryCounts.count) * 28))
                .padding()
            } else {
                Text("No log data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}
