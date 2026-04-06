//
//  SyncInfo.swift
//  wisetail-dashboard
//

import Foundation

struct SyncInfo: Codable {
    let lastFullSyncStart: Date?
    let lastFullSyncEnd: Date?
    let lastPartialSyncStart: Date?
    let lastPartialSyncEnd: Date?
    let lastFailureDate: Date?
    let lastFailureReason: String?
    let syncInterval: String?
    let backgroundSyncEnabled: Bool
    let backgroundRefreshStatus: String
    let syncPhaseStates: String?
    let onTrackSyncPhaseStates: String?
    let lastSyncCompletedDate: String?

    var fullSyncDuration: TimeInterval? {
        guard let start = lastFullSyncStart, let end = lastFullSyncEnd else { return nil }
        return end.timeIntervalSince(start)
    }

    var partialSyncDuration: TimeInterval? {
        guard let start = lastPartialSyncStart, let end = lastPartialSyncEnd else { return nil }
        return end.timeIntervalSince(start)
    }
}

struct SyncStatesData: Codable {
    let records: [SyncStateRecord]
}

struct SyncStateRecord: Codable, Identifiable {
    var id: String {
        "\(apiRoute ?? "unknown")_\(userId ?? "")_\(deviceId ?? "")"
    }

    let apiRoute: String?
    let userId: String?
    let deviceId: String?
    let fullSyncStartDate: Date?
    let fullSyncEndDate: Date?
    let fullSyncStatus: String?
    let partialSyncStartDate: Date?
    let partialSyncEndDate: Date?
    let partialSyncStatus: String?
    let lastFailureStartDate: Date?
    let lastFailureEndDate: Date?
    let lastFailureReason: String?
}
