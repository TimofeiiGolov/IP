// File: Pishi/Utilities/Constants.swift
import Foundation
import CoreGraphics

enum Constants {
    enum Strings {
        static let appName = "Пиши"
        static let notesTitle = "Заметки"
        static let untitled = "Без названия"
        static let emptyNote = "Пустая заметка"
        static let copySuffix = "Копия"
        static let newNote = "Новая заметка"
        static let searchPlaceholder = "Поиск"
        static let nothingFound = "Ничего не найдено"
        static let emptyStateTitle = "Пока нет заметок"
        static let emptyStateSubtitle = "Нажмите «Новая заметка», чтобы начать писать"
        static let saved = "Сохранено"
        static let saving = "Сохранение…"
        static let saveError = "Не удалось сохранить"
        static let delete = "Удалить"
        static let cancel = "Отмена"
        static let undoDelete = "Отменить удаление"
        static let settings = "Настройки"
        static let about = "О приложении"
        static let resetSettings = "Сбросить настройки"
        static let words = "Слов"
        static let characters = "Символов"
        static let lines = "Строк"
        static let titleField = "Заголовок"
        static let textField = "Текст заметки"
    }

    enum Accessibility {
        static let newNoteButton = "newNoteButton"
        static let settingsButton = "settingsButton"
        static let searchField = "searchField"
        static let displayModeToggle = "displayModeToggle"
        static let sortMenu = "sortMenu"
        static let filterMenu = "filterMenu"
        static let noteRow = "noteRow"
        static let titleField = "titleField"
        static let bodyField = "bodyField"
        static let backButton = "backButton"
        static let editorMenu = "editorMenu"
        static let saveStatus = "saveStatus"
        static let themePicker = "themePicker"
    }

    enum Layout {
        static let gridColumnsMinWidth: CGFloat = 160
        static let minimumTouchTarget: CGFloat = 44
    }
}
