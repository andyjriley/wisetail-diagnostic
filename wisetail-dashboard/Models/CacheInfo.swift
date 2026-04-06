//
//  CacheInfo.swift
//  wisetail-dashboard
//

import Foundation

struct CacheInfo: Codable {
    let currentCacheSizeBytes: Int64
    let cacheLimitBytes: Int64
    let utilizationPercentage: Double
    let totalCachedFiles: Int
    let deferredDownloadCount: Int
    let deferredDownloadSizeBytes: Int64
    let autoFillEnabled: Bool
    let wifiOnlyEnabled: Bool

    var formattedCurrentSize: String {
        ByteCountFormatter.string(fromByteCount: currentCacheSizeBytes, countStyle: .file)
    }

    var formattedLimit: String {
        cacheLimitBytes == 0 ? "Unlimited" : ByteCountFormatter.string(fromByteCount: cacheLimitBytes, countStyle: .file)
    }

    var formattedDeferredSize: String {
        ByteCountFormatter.string(fromByteCount: deferredDownloadSizeBytes, countStyle: .file)
    }
}
