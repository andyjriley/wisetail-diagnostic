//
//  DetailView.swift
//  wisetail-dashboard
//
//  Routes the selected sidebar section to its detail view.
//  Shows the import prompt when no bundle is loaded.
//

import SwiftUI

struct DetailView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        if viewModel.isLoaded {
            switch viewModel.selectedSection {
            case .overview:
                OverviewView()
            case .logs:
                LogViewerView()
            case .database:
                DatabaseBrowserView()
            case .syncTimeline:
                SyncTimelineView()
            case .statistics:
                StatisticsView()
            case .deviceInfo:
                DeviceInfoView()
            case .userDefaults:
                UserDefaultsView()
            case .keychain:
                KeychainView()
            case .serviceFiles:
                ServiceFilesView()
            case .cacheInfo:
                CacheInfoView()
            case .aiAssistant:
                AIAssistantView()
            }
        } else {
            ImportView()
        }
    }
}
