//
//  UserDefaultsView.swift
//  wisetail-dashboard
//
//  Searchable key-value table for UserDefaults data.
//

import SwiftUI

struct UserDefaultsView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var searchText = ""

    private var entries: [KeyValueEntry] {
        guard let data = viewModel.bundle?.userDefaults?.entries else { return [] }
        let sorted = data.sorted { $0.key < $1.key }
        if searchText.isEmpty { return sorted.map { KeyValueEntry(key: $0.key, value: $0.value) } }
        return sorted
            .filter {
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.value.localizedCaseInsensitiveContains(searchText)
            }
            .map { KeyValueEntry(key: $0.key, value: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search user defaults...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("\(entries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()

            Divider()

            if entries.isEmpty {
                ContentUnavailableView(
                    "No User Defaults",
                    systemImage: "gearshape",
                    description: Text("No user defaults data was included in this diagnostic bundle.")
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

                    TableColumn("Value") { entry in
                        Text(entry.value)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(entry.value == "not set" ? .tertiary : .primary)
                            .textSelection(.enabled)
                            .lineLimit(3)
                    }
                }
            }
        }
        .navigationTitle("User Defaults")
    }
}
