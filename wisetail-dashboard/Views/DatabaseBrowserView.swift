//
//  DatabaseBrowserView.swift
//  wisetail-dashboard
//
//  Entity picker + record detail table for browsing CoreData exports.
//  Data is loaded on-demand when the user navigates to this tab.
//

import SwiftUI

struct DatabaseBrowserView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        Group {
            if viewModel.databaseEntities == nil && viewModel.sectionLoading.contains(.database) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading database entities...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    // Entity list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Entities")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        List(selection: $vm.selectedEntity) {
                            ForEach(viewModel.entityNames, id: \.self) { name in
                                HStack {
                                    Label(name, systemImage: "tablecells")
                                    Spacer()
                                    Text("\(viewModel.databaseEntities?.entities[name]?.count ?? viewModel.bundle?.summary.entityRecordCounts[name] ?? 0)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.background.secondary)
                                        .clipShape(Capsule())
                                }
                                .tag(name)
                            }
                        }
                    }
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

                    // Records table
                    VStack(spacing: 0) {
                        if let entity = viewModel.selectedEntity {
                            HStack {
                                Text(entity)
                                    .font(.headline)

                                Spacer()

                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                    TextField("Search records...", text: $vm.databaseSearchText)
                                        .textFieldStyle(.plain)
                                }
                                .padding(6)
                                .background(.background.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .frame(maxWidth: 250)

                                Text("\(viewModel.selectedEntityRecords.count) records")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                            Divider()

                            if viewModel.selectedEntityRecords.isEmpty {
                                ContentUnavailableView(
                                    "No Records",
                                    systemImage: "tray",
                                    description: Text("No records found for \(entity)")
                                )
                            } else {
                                List(viewModel.selectedEntityRecords) { record in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ID: \(record.objectId)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)

                                        ForEach(record.attributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text(key)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundStyle(.blue)
                                                    .frame(width: 160, alignment: .trailing)

                                                Text(value)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .textSelection(.enabled)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "Select an Entity",
                                systemImage: "cylinder",
                                description: Text("Choose an entity from the list to view its records.")
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Database")
    }
}
