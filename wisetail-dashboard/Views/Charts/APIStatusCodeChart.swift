//
//  APIStatusCodeChart.swift
//  wisetail-dashboard
//
//  Bar chart of API response status codes.
//

import SwiftUI
import Charts

struct APIStatusCodeChart: View {
    let records: [APILogRecord]

    var body: some View {
        GroupBox("API Response Status Codes") {
            let filtered = records.filter { !$0.isError && $0.statusCode != nil }
            if !filtered.isEmpty {
                let statusCounts = Dictionary(grouping: filtered) { $0.statusCode ?? 0 }
                    .mapValues(\.count)
                    .sorted { $0.key < $1.key }

                Chart(statusCounts, id: \.key) { code, count in
                    BarMark(
                        x: .value("Status", "\(code)"),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(colorForStatusCode(code))
                }
                .frame(height: 200)
                .padding()
            } else {
                Text("No API log data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private func colorForStatusCode(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .yellow
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .gray
        }
    }
}
