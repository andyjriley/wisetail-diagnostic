//
//  KeyValueEntry.swift
//  wisetail-dashboard
//
//  A simple identifiable key-value pair for use in Table views.
//

import Foundation

struct KeyValueEntry: Identifiable {
    var id: String { key }
    let key: String
    let value: String
}
