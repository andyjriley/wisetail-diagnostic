//
//  StatisticsView.swift
//  wisetail-dashboard
//
//  Composes chart components for an overview of statistics.
//  Individual charts are in Views/Charts/.
//

import SwiftUI

struct StatisticsView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var isDataLoading: Bool {
        viewModel.isLoadingLogFile || viewModel.sectionLoading.contains(.syncTimeline)
    }

    var body: some View {
        Group {
            if isDataLoading && viewModel.apiLogs == nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading statistics data...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        LogLevelChart(entries: viewModel.logEntries ?? [])

                        APIStatusCodeChart(records: viewModel.apiLogs?.records ?? [])

                        HStack(spacing: 24) {
                            APIResponseTimeChart(records: viewModel.apiLogs?.records ?? [])
                            APISuccessErrorChart(records: viewModel.apiLogs?.records ?? [])
                        }

                        LogCategoryChart(entries: viewModel.logEntries ?? [])

                        SyncDurationChart(records: viewModel.syncStates?.records ?? [])
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Statistics")
    }
}
