//
//  ChatMessage.swift
//  wisetail-dashboard
//
//  Model for AI assistant chat messages.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    let timestamp: Date = Date()

    enum Role {
        case user
        case assistant
        case system
    }
}
