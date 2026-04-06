//
//  InfoRow.swift
//  wisetail-dashboard
//
//  Reusable label-value row for info sections.
//

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }
}
