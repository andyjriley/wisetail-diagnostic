//
//  DeviceInfoView.swift
//  wisetail-dashboard
//
//  Summary card with all device details.
//

import SwiftUI

struct DeviceInfoView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var device: DeviceInfo? { viewModel.bundle?.deviceInfo }

    var body: some View {
        ScrollView {
            if let device {
                VStack(alignment: .leading, spacing: 20) {
                    // Device Identity
                    GroupBox("Device Identity") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Device Name", value: device.deviceName)
                            InfoRow(label: "Device ID", value: device.deviceId)
                            InfoRow(label: "Serial Number", value: device.serialNumber.isEmpty ? "N/A" : device.serialNumber)
                            InfoRow(label: "Model", value: device.deviceModel)
                            InfoRow(label: "Machine Name", value: device.machineName)
                            InfoRow(label: "Device Type", value: device.deviceType.capitalized)
                            InfoRow(label: "Manufacturer", value: device.manufacturer)
                        }
                        .padding(.vertical, 4)
                    }

                    // Software
                    GroupBox("Software") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "iOS Version", value: device.iosVersion)
                            InfoRow(label: "App Version", value: device.appVersion)
                            InfoRow(label: "App Build", value: device.appBuild)
                            InfoRow(label: "Bundle ID", value: device.bundleIdentifier)
                            InfoRow(label: "Is Simulator", value: device.isSimulator ? "Yes" : "No")
                            InfoRow(label: "Is Catalyst", value: device.isCatalystApp ? "Yes" : "No")
                        }
                        .padding(.vertical, 4)
                    }

                    HStack(alignment: .top, spacing: 20) {
                        // Device Status
                        GroupBox("Device Status") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Approval State", value: device.approvalState)
                                InfoRow(label: "Device Mode", value: device.deviceMode.isEmpty ? "N/A" : device.deviceMode.capitalized)
                                InfoRow(label: "Mode Initialized", value: device.modeInitialized ? "Yes" : "No",
                                        valueColor: device.modeInitialized ? .green : .orange)
                                if let company = device.companyName {
                                    InfoRow(label: "Company", value: company)
                                }
                                if let baseUrl = device.baseUrl {
                                    InfoRow(label: "Base URL", value: baseUrl)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Hardware
                        GroupBox("Hardware") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Total Disk", value: device.formattedTotalDiskSpace)
                                InfoRow(label: "Free Disk", value: device.formattedFreeDiskSpace)
                                InfoRow(label: "Disk Usage", value: String(format: "%.1f%%", device.diskUsagePercentage))
                                InfoRow(label: "Battery Level", value: "\(device.batteryLevel)%")
                                InfoRow(label: "Battery State", value: device.batteryState)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Network
                    GroupBox("Network") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Network Reachable", value: device.networkReachable ? "Yes" : "No",
                                    valueColor: device.networkReachable ? .green : .red)
                            InfoRow(label: "Cellular", value: device.cellularReachable ? "Yes" : "No")
                            InfoRow(label: "WiFi", value: device.wifiReachable ? "Yes" : "No")
                        }
                        .padding(.vertical, 4)
                    }

                    // Notifications
                    GroupBox("Push Notifications") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "FCM Token", value: device.fcmToken ?? "Not Set")
                            InfoRow(label: "Last Received", value: device.lastNotificationReceived ?? "Never")
                            if let payload = device.lastNotificationPayload, !payload.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Last Payload")
                                        .foregroundStyle(.secondary)
                                    Text(payload)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(.background.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Device Info",
                    systemImage: "iphone.slash",
                    description: Text("Device information was not included in this diagnostic bundle.")
                )
            }
        }
        .navigationTitle("Device Info")
    }
}
