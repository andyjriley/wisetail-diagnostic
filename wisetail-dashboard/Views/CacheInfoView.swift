//
//  CacheInfoView.swift
//  wisetail-dashboard
//
//  Cache statistics display.
//

import SwiftUI
import Charts

struct CacheInfoView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var cache: CacheInfo? { viewModel.bundle?.cacheInfo }

    var body: some View {
        ScrollView {
            if let cache {
                VStack(alignment: .leading, spacing: 24) {
                    // Cache Usage Gauge
                    GroupBox("Cache Usage") {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                                    .frame(width: 150, height: 150)

                                Circle()
                                    .trim(from: 0, to: min(cache.utilizationPercentage / 100.0, 1.0))
                                    .stroke(
                                        gaugeColor(for: cache.utilizationPercentage),
                                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                    )
                                    .frame(width: 150, height: 150)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 2) {
                                    Text(String(format: "%.0f%%", cache.utilizationPercentage))
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Text("utilized")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()

                            HStack(spacing: 24) {
                                VStack {
                                    Text(cache.formattedCurrentSize)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Text("Current Size")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                VStack {
                                    Text(cache.formattedLimit)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Text("Limit")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    HStack(alignment: .top, spacing: 20) {
                        // Cache Details
                        GroupBox("Cache Details") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Current Size", value: cache.formattedCurrentSize)
                                InfoRow(label: "Cache Limit", value: cache.formattedLimit)
                                InfoRow(label: "Utilization", value: String(format: "%.1f%%", cache.utilizationPercentage))
                                InfoRow(label: "Total Cached Files", value: "\(cache.totalCachedFiles)")
                            }
                            .padding(.vertical, 4)
                        }

                        // Cache Settings
                        GroupBox("Cache Settings") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Auto-Fill Enabled", value: cache.autoFillEnabled ? "Yes" : "No",
                                        valueColor: cache.autoFillEnabled ? .green : .secondary)
                                InfoRow(label: "WiFi Only", value: cache.wifiOnlyEnabled ? "Yes" : "No")
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Deferred Downloads
                    if cache.deferredDownloadCount > 0 {
                        GroupBox("Deferred Downloads") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Pending Downloads", value: "\(cache.deferredDownloadCount)")
                                InfoRow(label: "Pending Size", value: cache.formattedDeferredSize)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Cache Data",
                    systemImage: "internaldrive",
                    description: Text("Cache information was not included in this diagnostic bundle.")
                )
            }
        }
        .navigationTitle("Cache")
    }

    private func gaugeColor(for percentage: Double) -> Color {
        switch percentage {
        case ..<50: return .green
        case 50..<80: return .yellow
        case 80..<95: return .orange
        default: return .red
        }
    }
}
