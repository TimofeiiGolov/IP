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
        let base = UIFont.systemFont(ofSize: settings.fontSize.basePointSize)
        let scaled = UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
        if let designed = UIFont(descriptor: descriptor.withDesign(settings.fontChoice.uiFontDesign) ?? descriptor,
                                 size: settings.fontSize.basePointSize) {
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: designed)
        }
        return scaled
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

private extension UIFontDescriptor {
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFontDescriptor? {
        addingAttributes([.systemDesign: design])
    }
}
