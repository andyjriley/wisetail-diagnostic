//
//  ManifestInfo.swift
//  wisetail-dashboard
//

import Foundation

struct ManifestInfo: Codable {
    let bundleVersion: Int
    let exportDate: Date
    let deviceName: String
    let deviceId: String
    let appVersion: String
    let appBuild: String
    let iosVersion: String
    let deviceModel: String
}
