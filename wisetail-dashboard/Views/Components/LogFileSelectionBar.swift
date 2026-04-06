//
//  LogFileSelectionBar.swift
//  wisetail-dashboard
//
//  Date and type picker toolbar for log file selection.
//

import SwiftUI

struct LogFileSelectionBar: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 16) {
            // Date picker
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Picker("Date", selection: $vm.selectedLogDate) {
                    Text("Select date...").tag(Optional<String>.none)
                    Divider()
                    ForEach(viewModel.logDates, id: \.self) { date in
                        Text(date).tag(Optional(date))
                    }
                }
                .frame(minWidth: 160)
            }

            // Type picker
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.secondary)
                Picker("Type", selection: $vm.selectedLogType) {
                    ForEach(LogFileType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .frame(minWidth: 120)
            }

            Spacer()

            // File info
            if let info = viewModel.selectedLogFileInfo {
                HStack(spacing: 8) {
                    Text(info.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let count = viewModel.logLineCount {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(count) entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("\(viewModel.logFiles.count) files total (\(viewModel.logTotalSize))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.background.secondary)
    }
}
