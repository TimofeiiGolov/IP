// File: Pishi/Views/SettingsView.swift
import SwiftUI

/// Экран настроек приложения.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                editorSection
                listSection
                aboutSection
                resetSection
            }
            .navigationTitle(Constants.Strings.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Готово")) { dismiss() }
                }
            }
        }
    }

    // MARK: - Разделы

    private var appearanceSection: some View {
        Section(String(localized: "Внешний вид")) {
            Picker(String(localized: "Тема"), selection: $settings.themeMode) {
                ForEach(SettingsStore.ThemeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .accessibilityIdentifier(Constants.Accessibility.themePicker)

            Picker(String(localized: "Размер шрифта"), selection: $settings.fontSize) {
                ForEach(SettingsStore.FontSizeOption.allCases) { size in
                    Text(size.title).tag(size)
                }
            }

            Picker(String(localized: "Шрифт"), selection: $settings.fontChoice) {
                ForEach(SettingsStore.FontChoice.allCases) { font in
                    Text(font.title).tag(font)
                }
            }
        }
    }

    private var editorSection: some View {
        Section(String(localized: "Редактор")) {
            Toggle(String(localized: "Автофокус при открытии"), isOn: $settings.autoFocus)
            Toggle(String(localized: "Перенос строк"), isOn: $settings.lineWrapping)

            Picker(String(localized: "Интервал автосохранения"), selection: $settings.autosaveInterval) {
                ForEach(SettingsStore.AutosaveInterval.allCases) { interval in
                    Text(interval.title).tag(interval)
                }
            }

            Toggle(String(localized: "Показывать статистику"), isOn: $settings.showStatistics)
            Toggle(String(localized: "Показывать слова"), isOn: $settings.showWordCount)
            Toggle(String(localized: "Показывать символы"), isOn: $settings.showCharacterCount)
        }
    }

    private var listSection: some View {
        Section(String(localized: "Список заметок")) {
            Picker(String(localized: "Отображение"), selection: $settings.displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }

            Picker(String(localized: "Сортировка по умолчанию"), selection: $settings.defaultSort) {
                ForEach(SortOption.allCases) { option in
                    Text(option.localizedName).tag(option)
                }
            }

            Toggle(String(localized: "Подтверждение удаления"), isOn: $settings.confirmDelete)
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "О приложении")) {
            LabeledContent(String(localized: "Название"), value: Constants.Strings.appName)
            LabeledContent(String(localized: "Версия"), value: SettingsStore.appVersion)
            LabeledContent(String(localized: "Технологии"), value: "SwiftUI · SwiftData · MVVM")
            Text(String(localized: "«Пиши» — быстрый минималистичный редактор заметок. Все данные хранятся только на вашем устройстве."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label(Constants.Strings.resetSettings, systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text(String(localized: "Сброс настроек не удаляет заметки."))
        }
        .confirmationDialog(
            Constants.Strings.resetSettings,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(Constants.Strings.resetSettings, role: .destructive) {
                settings.resetToDefaults()
            }
            Button(Constants.Strings.cancel, role: .cancel) {}
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore())
}
