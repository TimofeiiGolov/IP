// File: Pishi/App/PishiApp.swift
import SwiftUI
import SwiftData

@main
struct PishiApp: App {
    @State private var persistenceController = PersistenceController()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settingsStore)
                .tint(AppTheme.accent)
        }
        .modelContainer(persistenceController.modelContainer)
    }
}

/// Корневой контейнер: применяет тему из настроек.
struct RootView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NotesListView()
            .preferredColorScheme(settings.themeMode.colorScheme)
    }
}
