// File: Pishi/Services/SettingsStore.swift
import Foundation
import SwiftUI

/// Хранилище настроек на основе UserDefaults (AppStorage-совместимые ключи).
/// ObservableObject, чтобы View обновлялись при изменении настроек.
@MainActor
final class SettingsStore: ObservableObject {
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return String(localized: "Системная")
            case .light: return String(localized: "Светлая")
            case .dark: return String(localized: "Тёмная")
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    enum FontSizeOption: String, CaseIterable, Identifiable {
        case small
        case medium
        case large
        case extraLarge

        var id: String { rawValue }

        var title: String {
            switch self {
            case .small: return String(localized: "Мелкий")
            case .medium: return String(localized: "Средний")
            case .large: return String(localized: "Крупный")
            case .extraLarge: return String(localized: "Очень крупный")
            }
        }

        /// Базовый размер шрифта редактора (pt). Dynamic Type применяется через relativeTo.
        var basePointSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 17
            case .large: return 20
            case .extraLarge: return 24
            }
        }
    }

    enum FontChoice: String, CaseIterable, Identifiable {
        case system
        case serif
        case monospaced
        case rounded

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return String(localized: "Системный")
            case .serif: return String(localized: "С засечками")
            case .monospaced: return String(localized: "Моноширинный")
            case .rounded: return String(localized: "Скруглённый")
            }
        }

        var design: Font.Design {
            switch self {
            case .system: return .default
            case .serif: return .serif
            case .monospaced: return .monospaced
            case .rounded: return .rounded
            }
        }

        var uiFontDesign: UIFontDescriptor.SystemDesign {
            switch self {
            case .system: return .default
            case .serif: return .serif
            case .monospaced: return .monospaced
            case .rounded: return .rounded
            }
        }
    }

    enum AutosaveInterval: String, CaseIterable, Identifiable {
        case fast
        case normal
        case slow

        var id: String { rawValue }

        var title: String {
            switch self {
            case .fast: return String(localized: "0,5 секунды")
            case .normal: return String(localized: "1 секунда")
            case .slow: return String(localized: "2 секунды")
            }
        }

        var seconds: TimeInterval {
            switch self {
            case .fast: return 0.5
            case .normal: return 1.0
            case .slow: return 2.0
            }
        }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let themeMode = "settings.themeMode"
        static let fontSize = "settings.fontSize"
        static let fontChoice = "settings.fontChoice"
        static let showWordCount = "settings.showWordCount"
        static let showCharacterCount = "settings.showCharacterCount"
        static let showStatistics = "settings.showStatistics"
        static let autoFocus = "settings.autoFocus"
        static let autosaveInterval = "settings.autosaveInterval"
        static let displayMode = "settings.displayMode"
        static let defaultSort = "settings.defaultSort"
        static let confirmDelete = "settings.confirmDelete"
        static let lineWrapping = "settings.lineWrapping"
    }

    @Published var themeMode: ThemeMode
    @Published var fontSize: FontSizeOption
    @Published var fontChoice: FontChoice
    @Published var showWordCount: Bool
    @Published var showCharacterCount: Bool
    @Published var showStatistics: Bool
    @Published var autoFocus: Bool
    @Published var autosaveInterval: AutosaveInterval
    @Published var displayMode: DisplayMode
    @Published var defaultSort: SortOption
    @Published var confirmDelete: Bool
    @Published var lineWrapping: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        themeMode = ThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "") ?? .system
        fontSize = FontSizeOption(rawValue: defaults.string(forKey: Keys.fontSize) ?? "") ?? .medium
        fontChoice = FontChoice(rawValue: defaults.string(forKey: Keys.fontChoice) ?? "") ?? .system
        showWordCount = defaults.object(forKey: Keys.showWordCount) as? Bool ?? true
        showCharacterCount = defaults.object(forKey: Keys.showCharacterCount) as? Bool ?? true
        showStatistics = defaults.object(forKey: Keys.showStatistics) as? Bool ?? true
        autoFocus = defaults.object(forKey: Keys.autoFocus) as? Bool ?? true
        autosaveInterval = AutosaveInterval(rawValue: defaults.string(forKey: Keys.autosaveInterval) ?? "") ?? .normal
        displayMode = DisplayMode(rawValue: defaults.string(forKey: Keys.displayMode) ?? "") ?? .list
        defaultSort = SortOption(rawValue: defaults.string(forKey: Keys.defaultSort) ?? "") ?? .pinnedFirst
        confirmDelete = defaults.object(forKey: Keys.confirmDelete) as? Bool ?? true
        lineWrapping = defaults.object(forKey: Keys.lineWrapping) as? Bool ?? true
        persistAll()
    }

    /// Сброс настроек к значениям по умолчанию. Заметки НЕ удаляются.
    func resetToDefaults() {
        themeMode = .system
        fontSize = .medium
        fontChoice = .system
        showWordCount = true
        showCharacterCount = true
        showStatistics = true
        autoFocus = true
        autosaveInterval = .normal
        displayMode = .list
        defaultSort = .pinnedFirst
        confirmDelete = true
        lineWrapping = true
        persistAll()
    }

    private func persistAll() {
        defaults.set(themeMode.rawValue, forKey: Keys.themeMode)
        defaults.set(fontSize.rawValue, forKey: Keys.fontSize)
        defaults.set(fontChoice.rawValue, forKey: Keys.fontChoice)
        defaults.set(showWordCount, forKey: Keys.showWordCount)
        defaults.set(showCharacterCount, forKey: Keys.showCharacterCount)
        defaults.set(showStatistics, forKey: Keys.showStatistics)
        defaults.set(autoFocus, forKey: Keys.autoFocus)
        defaults.set(autosaveInterval.rawValue, forKey: Keys.autosaveInterval)
        defaults.set(displayMode.rawValue, forKey: Keys.displayMode)
        defaults.set(defaultSort.rawValue, forKey: Keys.defaultSort)
        defaults.set(confirmDelete, forKey: Keys.confirmDelete)
        defaults.set(lineWrapping, forKey: Keys.lineWrapping)
    }

    /// Версия приложения из Info.plist.
    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
