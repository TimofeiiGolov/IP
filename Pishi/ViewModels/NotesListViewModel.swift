// File: Pishi/ViewModels/NotesListViewModel.swift
import Foundation
import SwiftData
import SwiftUI

/// Состояние и бизнес-логика главного экрана списка заметок.
@MainActor
@Observable
final class NotesListViewModel {
    // MARK: - Состояние экрана

    var searchText: String = ""
    var filter: NoteFilter = .all
    var sortOption: SortOption = .pinnedFirst
    var displayMode: DisplayMode = .list
    var notes: [Note] = []
    var pendingDeletion: Note?
    var lastDeletedNote: Note?
    var showUndoBanner = false
    var importError: String?
    var showImportError = false

    private let persistence: PersistenceController
    private var undoTask: Task<Void, Never>?

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.filter = .all
        self.sortOption = .pinnedFirst
    }

    // MARK: - Загрузка и фильтрация

    func load() {
        let all: [Note]
        if filter == .archive {
            all = persistence.fetchArchivedNotes()
        } else {
            all = persistence.fetchNotes(includeArchived: false)
        }

        let searched: [Note]
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            searched = all
        } else {
            let lowered = query.lowercased()
            searched = all.filter {
                $0.title.lowercased().contains(lowered) || $0.text.lowercased().contains(lowered)
            }
        }

        notes = searched.sorted { sortOption.compare($0, $1) }
    }

    /// Закреплённые заметки (всегда сверху в режимах «Все» и «Недавно изменённые»).
    var pinnedNotes: [Note] {
        guard filter != .archive else { return [] }
        return notes.filter { $0.isPinned }
    }

    /// Остальные заметки.
    var unpinnedNotes: [Note] {
        guard filter != .archive else { return notes }
        return notes.filter { !$0.isPinned }
    }

    var isEmpty: Bool { notes.isEmpty }

    var isSearchEmpty: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && notes.isEmpty
    }

    // MARK: - Действия

    /// Создаёт новую заметку и возвращает её для открытия в редакторе.
    func createNote() -> Note {
        let note = Note()
        note.sortIndex = notes.count
        persistence.context.insert(note)
        persistence.save()
        load()
        return note
    }

    /// Удаляет заметку с возможностью отмены (undo-механизм вместо диалога).
    func delete(_ note: Note) {
        persistence.delete(note)
        lastDeletedNote = note
        showUndoBanner = true
        load()

        undoTask?.cancel()
        undoTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            self?.showUndoBanner = false
            self?.lastDeletedNote = nil
        }
    }

    /// Отменяет последнее удаление.
    func undoDelete() {
        guard let note = lastDeletedNote else { return }
        persistence.context.insert(note)
        persistence.save()
        lastDeletedNote = nil
        showUndoBanner = false
        undoTask?.cancel()
        load()
    }

    func togglePin(_ note: Note) {
        persistence.togglePinned(note)
        load()
    }

    func archive(_ note: Note) {
        persistence.archive(note)
        load()
    }

    func restore(_ note: Note) {
        persistence.restore(note)
        load()
    }

    /// Дублирует заметку и возвращает копию для открытия.
    func duplicate(_ note: Note) -> Note {
        let copy = persistence.duplicate(note)
        load()
        return copy
    }

    /// Импортирует файл: создаёт заметку с именем файла в заголовке.
    func importFile(from url: URL) -> Note? {
        do {
            let imported = try ImportService.importNote(from: url)
            let note = Note(title: imported.title, text: imported.text)
            persistence.context.insert(note)
            persistence.save()
            load()
            return note
        } catch {
            importError = error.localizedDescription
            showImportError = true
            return nil
        }
    }

    func applySettings(_ settings: SettingsStore) {
        displayMode = settings.displayMode
        sortOption = settings.defaultSort
    }
}
