//
//  DashboardViewModel.swift
//  wisetail-dashboard
//
//  Core state and actions for the diagnostic dashboard.
//  Log-related logic is in DashboardViewModel+Logs.swift.
//  Section loading is in DashboardViewModel+SectionLoading.swift.
//

import Foundation
import Observation

@Observable
class DashboardViewModel {
    // MARK: - Core State

    var bundle: DiagnosticBundle?
    var isLoading = false
    var errorMessage: String?
    var showFileImporter = false
    var selectedSection: SidebarSection = .overview {
        didSet { loadSectionIfNeeded(selectedSection) }
    }

    // MARK: - Lazy-loaded heavy data (nil = not yet loaded)

    var logEntries: [LogEntry]?
    var databaseEntities: DatabaseEntities?
    var syncStates: SyncStatesData?
    var apiLogs: APILogsData?
    var serviceFileContent: [String: String] = [:]
    var sectionLoading: Set<SidebarSection> = []
    var loadedSections: Set<SidebarSection> = []

    // MARK: - Log file selection

    var selectedLogDate: String? {
        didSet {
            guard oldValue != selectedLogDate else { return }
            loadSelectedLogFile()
        }
    }
    var selectedLogType: LogFileType = .app {
        didSet {
            guard oldValue != selectedLogType else { return }
            loadSelectedLogFile()
        }
    }
    var loadedLogFilename: String?
    var isLoadingLogFile = false

    // MARK: - Filtering

    var logSearchText = ""
    var selectedLogLevel: LogLevel?
    var selectedLogCategory: String?
    var selectedEntity: String?
    var databaseSearchText = ""

    // MARK: - Computed Overview Stats

    var isLoaded: Bool { bundle != nil }
    var totalApiCalls: Int { bundle?.summary.apiCallCount ?? 0 }
    var apiErrorCount: Int { bundle?.summary.apiErrorCount ?? 0 }
    var entityNameCount: Int { bundle?.summary.entityNames.count ?? 0 }
    var syncStateCount: Int { bundle?.summary.syncStateCount ?? 0 }

    // MARK: - Database

    var entityNames: [String] {
        if let entities = databaseEntities?.entities {
            return entities.keys.sorted()
        }
        return bundle?.summary.entityNames ?? []
    }

    var selectedEntityRecords: [EntityRecord] {
        guard let entity = selectedEntity,
              let records = databaseEntities?.entities[entity] else { return [] }
        if databaseSearchText.isEmpty { return records }
        return records.filter { record in
            record.attributes.values.contains { $0.localizedCaseInsensitiveContains(databaseSearchText) }
        }
    }

    // MARK: - Service Files

    var serviceFileNames: [String] {
        bundle?.summary.serviceFileNames ?? []
    }

    func serviceFileContentFor(_ name: String) -> String? {
        if let cached = serviceFileContent[name] { return cached }
        guard let rootDir = bundle?.rootDir else { return nil }
        let content = BundleParser.loadServiceFile(rootDir: rootDir, name: name)
        if let content {
            serviceFileContent[name] = content
        }
        return content
    }

    // MARK: - Actions

    func loadBundle(from url: URL) {
        isLoading = true
        errorMessage = nil
        print("[ViewModel] loadBundle called for: \(url.lastPathComponent)")

        Task { [weak self] in
            do {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }

                print("[ViewModel] Starting background parse...")
                let parsed = try await Task.detached {
                    try BundleParser.parse(url: url)
                }.value
                print("[ViewModel] Background parse returned, updating UI...")

                guard let self else { return }
                self.resetLazyData()
                self.bundle = parsed
                self.isLoading = false
                self.selectedSection = .overview
                self.selectedEntity = parsed.summary.entityNames.first
                print("[ViewModel] Bundle loaded successfully, showing overview")
            } catch {
                print("[ViewModel] ERROR loading bundle: \(error.localizedDescription)")
                guard let self else { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func clearBundle() {
        bundle = nil
        resetLazyData()
        errorMessage = nil
        selectedSection = .overview
        logSearchText = ""
        selectedLogLevel = nil
        selectedLogCategory = nil
        selectedEntity = nil
        databaseSearchText = ""
        selectedLogDate = nil
        selectedLogType = .app
    }

    private func resetLazyData() {
        logEntries = nil
        databaseEntities = nil
        syncStates = nil
        apiLogs = nil
        serviceFileContent = [:]
        loadedSections = []
        sectionLoading = []
        loadedLogFilename = nil
        isLoadingLogFile = false
    }
}
