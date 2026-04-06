//
//  DeviceInfo.swift
//  wisetail-dashboard
//

import Foundation

struct DeviceInfo: Codable {
    let deviceName: String
    let deviceId: String
    let serialNumber: String
    let iosVersion: String
    let deviceModel: String
    let machineName: String
    let deviceType: String
    let manufacturer: String
    let approvalState: String
    let deviceMode: String
    let modeInitialized: Bool
    let appVersion: String
    let appBuild: String
    let bundleIdentifier: String
    let totalDiskSpaceBytes: Int64
    let freeDiskSpaceBytes: Int64
    let batteryLevel: Int
    let batteryState: String
    let isSimulator: Bool
    let isCatalystApp: Bool
    let networkReachable: Bool
    let cellularReachable: Bool
    let wifiReachable: Bool
    let fcmToken: String?
    let lastNotificationReceived: String?
    let lastNotificationPayload: String?
    let companyName: String?
    let baseUrl: String?

    var formattedTotalDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: totalDiskSpaceBytes, countStyle: .file)
    }

    var formattedFreeDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: freeDiskSpaceBytes, countStyle: .file)
    }

    var usedDiskSpaceBytes: Int64 {
        totalDiskSpaceBytes - freeDiskSpaceBytes
    }

    var diskUsagePercentage: Double {
        guard totalDiskSpaceBytes > 0 else { return 0 }
        return Double(usedDiskSpaceBytes) / Double(totalDiskSpaceBytes) * 100
    }
}
