// File: Pishi/Utilities/AppTheme.swift
import SwiftUI
import UIKit

/// Централизованная тема приложения: цвета и шрифты.
enum AppTheme {
    static let accent = Color.accentColor
    static let cardBackground = Color(.secondarySystemBackground)
    static let secondaryText = Color.secondary

    /// UIFont редактора с учётом настроек пользователя.
    @MainActor
    static func editorUIFont(settings: SettingsStore) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let designed = descriptor.withDesign(settings.fontChoice.uiFontDesign) ?? descriptor
        let font = UIFont(descriptor: designed, size: settings.fontSize.basePointSize)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// Шрифт заголовка редактора.
    @MainActor
    static func titleFont(settings: SettingsStore) -> Font {
        .system(size: settings.fontSize.basePointSize + 8, weight: .bold, design: settings.fontChoice.design)
    }

    /// Шрифт текста редактора (SwiftUI).
    @MainActor
    static func bodyFont(settings: SettingsStore) -> Font {
        .system(size: settings.fontSize.basePointSize, design: settings.fontChoice.design)
    }
}
