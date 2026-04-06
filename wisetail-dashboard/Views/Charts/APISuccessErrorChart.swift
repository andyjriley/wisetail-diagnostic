//
//  APISuccessErrorChart.swift
//  wisetail-dashboard
//
//  Donut chart showing API success vs error ratio.
//

import SwiftUI
import Charts

struct APISuccessErrorChart: View {
    let records: [APILogRecord]

    var body: some View {
        GroupBox("API Success vs Errors") {
            if !records.isEmpty {
                let errorCount = records.filter(\.isError).count
                let successCount = records.count - errorCount

                Chart {
                    SectorMark(
                        angle: .value("Count", successCount),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(.green)

                    SectorMark(
                        angle: .value("Count", errorCount),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(.red)
                }
                .frame(height: 200)
                .padding()

                HStack(spacing: 16) {
                    Label("Success: \(successCount)", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Label("Errors: \(errorCount)", systemImage: "circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                .padding(.bottom, 8)
            } else {
                Text("No API log data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}
