//
//  DashboardViewModel+SectionLoading.swift
//  wisetail-dashboard
//
//  Lazy section loading — loads heavy data from disk on-demand
//  when the user navigates to a tab.
//

import Foundation

extension DashboardViewModel {

    /// Called automatically when the user navigates to a tab.
    /// Loads the required heavy data from disk if not already loaded.
    func loadSectionIfNeeded(_ section: SidebarSection) {
        guard let rootDir = bundle?.rootDir else { return }

        let neededSections: Set<SidebarSection>
        switch section {
        case .overview:
            return
        case .logs:
            if selectedLogDate == nil, let firstDate = logDates.first {
                selectedLogDate = firstDate
            }
            return
        case .database:
            neededSections = [.database]
        case .syncTimeline:
            neededSections = [.syncTimeline]
        case .statistics:
            neededSections = [.syncTimeline]
        case .serviceFiles:
            return
        default:
            return
        }

        for needed in neededSections {
            guard !loadedSections.contains(needed) && !sectionLoading.contains(needed) else { continue }

            sectionLoading.insert(needed)
            print("[ViewModel] Loading section: \(needed.rawValue)")

            Task { [weak self] in
                switch needed {
                case .database:
                    print("[ViewModel:DB] Starting background entity parse...")
                    let entities = await Task.detached {
                        BundleParser.loadDatabaseEntities(rootDir: rootDir)
                    }.value
                    guard let self else { return }
                    print("[ViewModel:DB] Assigning \(entities?.entities.count ?? 0) entity types to UI")
                    self.databaseEntities = entities
                    if self.selectedEntity == nil {
                        self.selectedEntity = entities?.entities.keys.sorted().first
                    }
                    self.loadedSections.insert(.database)
                    self.sectionLoading.remove(.database)
                    print("[ViewModel:DB] Done")

                case .syncTimeline:
                    print("[ViewModel:Sync] Starting background sync/API parse...")
                    let (states, logs) = await Task.detached {
                        let s = BundleParser.loadSyncStates(rootDir: rootDir)
                        let l = BundleParser.loadAPILogs(rootDir: rootDir)
                        return (s, l)
                    }.value
                    guard let self else { return }
                    print("[ViewModel:Sync] Assigning \(states?.records.count ?? 0) sync states + \(logs?.records.count ?? 0) API logs to UI")
                    self.syncStates = states
                    self.apiLogs = logs
                    self.loadedSections.insert(.syncTimeline)
                    self.sectionLoading.remove(.syncTimeline)
                    print("[ViewModel:Sync] Done")

                default:
                    break
                }
            }
        }
    }
}
