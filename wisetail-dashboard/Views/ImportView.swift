//
//  ImportView.swift
//  wisetail-dashboard
//
//  Drag-and-drop landing screen for importing .wldiag files.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "shippingbox")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("WiseLync Diagnostic Viewer")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Open a .wldiag diagnostic bundle to view device logs, database records, sync history, and more.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .frame(width: 400, height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDragging ? Color.accentColor.opacity(0.05) : Color.clear)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 32))
                        .foregroundStyle(isDragging ? Color.accentColor : .secondary)

                    Text("Drop .wldiag file here")
                        .font(.headline)
                        .foregroundStyle(isDragging ? Color.accentColor : .secondary)

                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button("Choose File...") {
                        viewModel.showFileImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .padding()
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                Task { @MainActor in
                    viewModel.loadBundle(from: url)
                }
            }
        }
        return true
    }
}
