//
//  APIResponseTimeChart.swift
//  wisetail-dashboard
//
//  Histogram of API response time buckets.
//

import SwiftUI
import Charts

struct APIResponseTimeChart: View {
    let records: [APILogRecord]

    var body: some View {
        GroupBox("API Response Times") {
            let filtered = records.filter { $0.duration != nil && !$0.isError }
            if !filtered.isEmpty {
                let buckets = responseBuckets(from: filtered)

                Chart(buckets, id: \.label) { bucket in
                    BarMark(
                        x: .value("Duration", bucket.label),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 200)
                .padding()
            } else {
                Text("No response time data available")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private struct Bucket {
        let label: String
        let count: Int
    }

    private func responseBuckets(from records: [APILogRecord]) -> [Bucket] {
        let durations = records.compactMap(\.duration)
        guard !durations.isEmpty else { return [] }

        var buckets: [String: Int] = [
            "<0.5s": 0, "0.5-1s": 0, "1-2s": 0,
            "2-5s": 0, "5-10s": 0, ">10s": 0,
        ]
        let order = ["<0.5s", "0.5-1s", "1-2s", "2-5s", "5-10s", ">10s"]

        for d in durations {
            switch d {
            case ..<0.5:   buckets["<0.5s", default: 0] += 1
            case 0.5..<1:  buckets["0.5-1s", default: 0] += 1
            case 1..<2:    buckets["1-2s", default: 0] += 1
            case 2..<5:    buckets["2-5s", default: 0] += 1
            case 5..<10:   buckets["5-10s", default: 0] += 1
            default:       buckets[">10s", default: 0] += 1
            }
        }

        return order.map { Bucket(label: $0, count: buckets[$0] ?? 0) }
    }
}
