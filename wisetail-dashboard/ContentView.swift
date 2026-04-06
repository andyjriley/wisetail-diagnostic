//
//  ContentView.swift
//  wisetail-dashboard
//
//  Created by Andrew Riley on 2/6/26.
//
//  Layout: optional section sidebar (after bundle load) | detail / import.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 0) {
            if viewModel.isLoaded {
                SectionListView()
                    .frame(width: 220)

                Divider()
            }

            DetailView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileImporter(
            isPresented: $vm.showFileImporter,
            allowedContentTypes: [.data, .archive],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.loadBundle(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading diagnostic bundle...")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle("WiseLync Diagnostic Viewer")
    }
}

// MARK: - Section List

private struct SectionListView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            sectionHeader
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            List(selection: $vm.selectedSection) {
                diagnosticSections
            }
            .listStyle(.sidebar)
        }
        .background(.windowBackground)
    }

    @ViewBuilder
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Diagnostics")
                    .font(.headline)
                if let name = viewModel.bundle?.manifest.deviceName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button {
                viewModel.showFileImporter = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Open Bundle")

            Button {
                viewModel.clearBundle()
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Close Bundle")
        }
    }

    private var diagnosticSections: some View {
        ForEach(SidebarSection.diagnosticSections) { section in
            Label(section.rawValue, systemImage: section.iconName)
                .tag(section)
        }
    }
}
