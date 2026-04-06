//
//  StatCard.swift
//  wisetail-dashboard
//
//  Reusable stat card used in OverviewView and elsewhere.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
