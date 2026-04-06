//
//  KeychainView.swift
//  wisetail-dashboard
//
//  Keychain status table showing key statuses.
//

import SwiftUI

struct KeychainView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var entries: [KeyValueEntry] {
        guard let data = viewModel.bundle?.keychainInfo?.entries else { return [] }
        return data.sorted { $0.key < $1.key }.map { KeyValueEntry(key: $0.key, value: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Keychain Data",
                    systemImage: "key",
                    description: Text("Keychain data was not included in this diagnostic bundle.")
                )
            } else {
                Table(entries) {
                    TableColumn("Key") { entry in
                        Text(entry.key)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                    }
                    .width(min: 200, ideal: 300)

                    TableColumn("Status") { entry in
                        HStack {
                            Circle()
                                .fill(statusColor(entry.value))
                                .frame(width: 8, height: 8)
                            Text(entry.value)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(statusColor(entry.value))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle("Keychain")
    }

    private func statusColor(_ value: String) -> Color {
        if value.contains("exists") || value.contains("Set") {
            return .green
        } else if value.contains("not found") || value.contains("Not") {
            return .secondary
        } else if value.contains("error") {
            return .red
        }
        return .primary
    }
}
