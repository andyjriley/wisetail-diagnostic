//
//  DatabaseRecord.swift
//  wisetail-dashboard
//

import Foundation

struct DatabaseEntities: Codable {
    let entities: [String: [EntityRecord]]
}

struct EntityRecord: Codable, Identifiable, Hashable {
    var id: String { objectId }
    let objectId: String
    let attributes: [String: String]
}

struct APILogsData: Codable {
    let records: [APILogRecord]
}

struct APILogRecord: Codable, Identifiable {
    let id = UUID()

    // LogServiceHistory fields
    let url: String?
    let method: String?
    let statusCode: Int?
    let duration: Double?
    let retryCount: Int?
    let connectionStartDate: Date?
    let fetchStartDate: Date?
    let syncType: String?
    let endReason: String?
    let instigator: String?
    // LogServiceErrorHistory fields
    let isError: Bool
    let errorDomain: String?
    let errorCode: Int?
    let errorMessage: String?
    let errorDate: Date?
    let errorReason: String?
    let errorResponseString: String?
    let errorStatusCode: Int?

    /// Best available date for sorting/display
    var effectiveDate: Date? {
        connectionStartDate ?? fetchStartDate ?? errorDate
    }

    var formattedDuration: String {
        guard let duration else { return "N/A" }
        return String(format: "%.2fs", duration)
    }

    var shortUrl: String {
        guard let url else { return "N/A" }
        if let urlObj = URL(string: url) {
            return urlObj.lastPathComponent
        }
        return url
    }

    enum CodingKeys: String, CodingKey {
        case url, method, statusCode, duration, retryCount
        case connectionStartDate, fetchStartDate, syncType, endReason, instigator
        case isError, errorDomain, errorCode, errorMessage
        case errorDate, errorReason, errorResponseString, errorStatusCode
    }
}

struct UserDefaultsData: Codable {
    let entries: [String: String]
}

struct KeychainData: Codable {
    let entries: [String: String]
}
