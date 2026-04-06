//
//  wisetail_dashboardApp.swift
//  wisetail-dashboard
//
//  Created by Andrew Riley on 2/6/26.
//

import Combine
import Sparkle
import SwiftUI

// MARK: - Sparkle Update Helper

/// Observes the Sparkle updater's `canCheckForUpdates` property so SwiftUI
/// can reactively enable or disable the "Check for Updates…" menu item.
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

/// A SwiftUI view used as a menu item that triggers Sparkle's update check.
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesVM: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesVM = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesVM.canCheckForUpdates)
    }
}

// MARK: - App Entry Point

@main
struct wisetail_dashboardApp: App {
    @State private var viewModel = DashboardViewModel()

    /// Sparkle updater controller — must be retained for the app's lifetime.
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .commands {
            // "Check for Updates…" in the app menu, right after "About"
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }

            CommandGroup(replacing: .newItem) {
                Button("Open Diagnostic Bundle...") {
                    viewModel.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
