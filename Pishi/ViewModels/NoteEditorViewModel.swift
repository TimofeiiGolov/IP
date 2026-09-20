// File: Pishi/ViewModels/NoteEditorViewModel.swift
import Foundation
import SwiftData
import SwiftUI
import Combine

/// Статус сохранения для отображения в редакторе.
enum SaveStatus: Equatable {
    case saved(Date)
    case saving
    case error(String)

    var displayText: String {
        switch self {
        case .saved(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return "\(Constants.Strings.saved) · \(formatter.string(from: date))"
        case .saving:
            return Constants.Strings.saving
        case .error:
            return Constants.Strings.saveError
        }
    }
}

/// Состояние и бизнес-логика экрана редактора заметки.
@MainActor
@Observable
final class NoteEditorViewModel {
    // MARK: - Состояние

    var title: String
    var text: String
    var saveStatus: SaveStatus = .saved(.now)
    var isSearchVisible = false
    var inNoteSearchQuery = ""
    var currentMatchIndex = 0
    var hasUnsavedChanges = false

    let note: Note
    private let persistence: PersistenceController
    private var debounceTask: Task<Void, Never>?
    private let autosaveInterval: TimeInterval
    // nonisolated(unsafe): обращение только в init и deinit.
    private nonisolated(unsafe) var backgroundObserver: NSObjectProtocol?

    /// Держатель UITextView для команд undo/redo из тулбара.
    let textViewHolder = TextViewHolder()

    /// Совпадения поиска внутри текста (диапазоны в символах String).
    var searchMatches: [Range<String.Index>] {
        let query = inNoteSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text.range(of: query, options: .caseInsensitive, range: searchStart..<text.endIndex) {
            ranges.append(range)
            searchStart = range.lowerBound < range.upperBound ? range.upperBound : text.index(after: range.lowerBound)
        }
        return ranges
    }

    var matchCount: Int { searchMatches.count }

    var currentMatchRange: Range<String.Index>? {
        let matches = searchMatches
        guard !matches.isEmpty else { return nil }
        let index = min(max(currentMatchIndex, 0), matches.count - 1)
        return matches[index]
    }

    // MARK: - Статистика

    var wordCount: Int { text.computedWordCount }
    var characterCount: Int { text.count }
    var lineCount: Int { text.computedLineCount }
    var updatedAt: Date { note.updatedAt }

    // MARK: - Init

    init(note: Note, persistence: PersistenceController, autosaveInterval: TimeInterval = 1.0) {
        self.note = note
        self.persistence = persistence
        self.title = note.title
        self.text = note.text
        self.autosaveInterval = autosaveInterval

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveNow()
            }
        }
    }

    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Автосохранение (debounce)

    /// Вызывается при каждом изменении текста: планирует сохранение через debounce.
    func contentChanged() {
        hasUnsavedChanges = true
        saveStatus = .saving
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.autosaveInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.saveNow()
        }
    }

    /// Немедленное сохранение: при закрытии редактора, уходе в background, смене заметки.
    func saveNow() {
        debounceTask?.cancel()
        guard hasUnsavedChanges else { return }
        saveStatus = .saving
        let ok = persistence.updateContent(of: note, title: title, text: text)
        if ok {
            hasUnsavedChanges = false
            saveStatus = .saved(.now)
        } else {
            saveStatus = .error(Constants.Strings.saveError)
        }
    }

    /// Проверка: нужно ли сохранять пустую новую заметку.
    /// Пустые заметки (без заголовка и текста) не оставляем в базе.
    func cleanupEmptyNoteIfNeeded() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty && trimmedText.isEmpty && note.createdAt == note.updatedAt {
            persistence.delete(note)
        } else {
            saveNow()
        }
    }

    // MARK: - Поиск внутри заметки

    func nextMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchCount
    }

    func previousMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchCount) % matchCount
    }

    func closeSearch() {
        isSearchVisible = false
        inNoteSearchQuery = ""
        currentMatchIndex = 0
    }

    // MARK: - Undo/Redo

    var canUndo: Bool { textViewHolder.textView?.undoManager?.canUndo ?? false }
    var canRedo: Bool { textViewHolder.textView?.undoManager?.canRedo ?? false }

    func undo() { textViewHolder.textView?.undoManager?.undo() }
    func redo() { textViewHolder.textView?.undoManager?.redo() }

    // MARK: - Действия меню

    func togglePin() {
        persistence.togglePinned(note)
    }

    func toggleArchive() {
        persistence.setArchived(note, archived: !note.isArchived)
    }

    /// Дублирует заметку и возвращает копию для открытия.
    func duplicate() -> Note {
        saveNow()
        return persistence.duplicate(note)
    }

    func deleteNote() {
        debounceTask?.cancel()
        hasUnsavedChanges = false
        persistence.delete(note)
    }

    /// URL файла для экспорта.
    func exportURL(format: ExportService.ExportFormat) throws -> URL {
        saveNow()
        return try ExportService.exportFile(title: note.displayTitle, text: text, format: format)
    }
}
