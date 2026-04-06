//
//  ServiceFilesView.swift
//  wisetail-dashboard
//
//  JSON tree viewer for service files.
//  File content is loaded on-demand when the user selects a file.
//

import SwiftUI

struct ServiceFilesView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var selectedFile: String?
    @State private var loadedContent: String?

    private var fileNames: [String] {
        viewModel.serviceFileNames
    }

    var body: some View {
        HSplitView {
            // File list
            VStack(alignment: .leading, spacing: 0) {
                Text("Service Files")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                List(fileNames, id: \.self, selection: $selectedFile) { name in
                    Label(name, systemImage: "doc.text")
                        .tag(name)
                }
            }
            .frame(minWidth: 200, idealWidth: 250)

            // Content viewer
            Group {
                if let fileName = selectedFile {
                    let content = viewModel.serviceFileContentFor(fileName)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(fileName)
                                .font(.headline)
                            Spacer()
                            if let content {
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(content, forType: .string)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        }
                        .padding()

                        Divider()

                        if let content {
                            ScrollView([.horizontal, .vertical]) {
                                Text(content)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Loading file...")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        fileNames.isEmpty ? "No Service Files" : "Select a File",
                        systemImage: "doc.on.doc",
                        description: Text(
                            fileNames.isEmpty
                                ? "No service files were included in this diagnostic bundle."
                                : "Choose a service file from the list to view its contents."
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
