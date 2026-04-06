//
//  OverviewView.swift
//  wisetail-dashboard
//
//  Summary card showing device info, export metadata, and quick diagnostic stats.
//  All counts come from the lightweight BundleSummary — no heavy data loading.
//

import SwiftUI

struct OverviewView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var bundle: DiagnosticBundle? { viewModel.bundle }
    private var manifest: ManifestInfo? { bundle?.manifest }
    private var device: DeviceInfo? { bundle?.deviceInfo }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: "iphone")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(manifest?.deviceName ?? "Unknown Device")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Exported \(formattedExportDate)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let device {
                            Text("\(device.appVersion) (\(device.appBuild)) - iOS \(device.iosVersion)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let device {
                        VStack(alignment: .trailing, spacing: 4) {
                            Label(device.deviceMode.isEmpty ? "Unknown" : device.deviceMode.capitalized, systemImage: "lock.shield")
                            Label(device.companyName ?? "N/A", systemImage: "building.2")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Quick Stats Grid — uses summary counts (no heavy data)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Log Files",
                        value: "\(viewModel.logFiles.count)",
                        icon: "doc.text",
                        color: .blue,
                        subtitle: viewModel.logTotalSize
                    )
                    StatCard(
                        title: "Errors",
                        value: viewModel.errorLogCount.map { "\($0)" } ?? "–",
                        icon: "exclamationmark.triangle.fill",
                        color: (viewModel.errorLogCount ?? 0) > 0 ? .red : .green,
                        subtitle: viewModel.errorLogCount == nil ? "Load Logs tab" : nil
                    )
                    StatCard(
                        title: "Warnings",
                        value: viewModel.warningLogCount.map { "\($0)" } ?? "–",
                        icon: "exclamationmark.circle",
                        color: (viewModel.warningLogCount ?? 0) > 0 ? .orange : .green,
                        subtitle: viewModel.warningLogCount == nil ? "Load Logs tab" : nil
                    )
                    StatCard(
                        title: "API Calls",
                        value: "\(viewModel.totalApiCalls)",
                        icon: "network",
                        color: .purple
                    )
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "API Errors",
                        value: "\(viewModel.apiErrorCount)",
                        icon: "xmark.circle",
                        color: viewModel.apiErrorCount > 0 ? .red : .green
                    )
                    StatCard(
                        title: "DB Entities",
                        value: "\(viewModel.entityNameCount)",
                        icon: "cylinder",
                        color: .indigo
                    )
                    StatCard(
                        title: "Cached Files",
                        value: "\(bundle?.cacheInfo?.totalCachedFiles ?? 0)",
                        icon: "internaldrive",
                        color: .teal
                    )
                    StatCard(
                        title: "Sync States",
                        value: "\(viewModel.syncStateCount)",
                        icon: "arrow.triangle.2.circlepath",
                        color: .cyan
                    )
                }

                // Sync Status
                if let syncInfo = bundle?.syncInfo {
                    GroupBox("Sync Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Last Full Sync", value: formatDate(syncInfo.lastFullSyncEnd))
                            InfoRow(label: "Last Partial Sync", value: formatDate(syncInfo.lastPartialSyncEnd))
                            InfoRow(label: "Background Sync", value: syncInfo.backgroundSyncEnabled ? "Enabled" : "Disabled")
                            InfoRow(label: "Background Refresh", value: syncInfo.backgroundRefreshStatus.capitalized)
                            if let interval = syncInfo.syncInterval {
                                InfoRow(label: "Sync Interval", value: "\(interval) minutes")
                            }
                            if let reason = syncInfo.lastFailureReason {
                                InfoRow(label: "Last Failure", value: reason, valueColor: .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Device Storage
                if let device {
                    GroupBox("Storage") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Total Disk", value: device.formattedTotalDiskSpace)
                            InfoRow(label: "Free Disk", value: device.formattedFreeDiskSpace)
                            InfoRow(label: "Disk Usage", value: String(format: "%.1f%%", device.diskUsagePercentage))
                            if let cache = bundle?.cacheInfo {
                                InfoRow(label: "Cache Size", value: cache.formattedCurrentSize)
                                InfoRow(label: "Cache Limit", value: cache.formattedLimit)
                                InfoRow(label: "Cache Utilization", value: String(format: "%.1f%%", cache.utilizationPercentage))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Overview")
    }

    private var formattedExportDate: String {
        guard let date = manifest?.exportDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

