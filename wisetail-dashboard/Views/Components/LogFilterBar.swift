//
//  LogFilterBar.swift
//  wisetail-dashboard
//
//  Search, level, and category filter toolbar for log entries.
//

import SwiftUI

struct LogFilterBar: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search logs...", text: $vm.logSearchText)
                    .textFieldStyle(.plain)
                if !viewModel.logSearchText.isEmpty {
                    Button {
                        viewModel.logSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Level filter
            Picker("Level", selection: $vm.selectedLogLevel) {
                Text("All Levels").tag(Optional<LogLevel>.none)
                Divider()
                ForEach(LogLevel.allCases) { level in
                    Text(level.rawValue).tag(Optional(level))
                }
            }
            .frame(width: 140)

            // Category filter
            Picker("Category", selection: $vm.selectedLogCategory) {
                Text("All Categories").tag(Optional<String>.none)
                Divider()
                ForEach(viewModel.logCategories, id: \.self) { category in
                    Text(category).tag(Optional(category))
                }
            }
            .frame(width: 160)

            Spacer()

            Text("\(viewModel.filteredLogEntries.count) entries")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
