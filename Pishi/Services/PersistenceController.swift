// File: Pishi/Services/PersistenceController.swift
import Foundation
import SwiftData

/// Управление ModelContainer и всеми операциями с заметками.
/// Production-контейнер создаётся один раз; для тестов доступен in-memory контейнер.
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let modelContainer: ModelContainer

    /// Создание контейнера с обработкой ошибок:
    /// при неудаче (например, повреждение базы) контейнер пересоздаётся заново.
    init(inMemory: Bool = false) {
        let schema = Schema([Note.self])
        if inMemory {
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
                return
            } catch {
                fatalError("Не удалось создать in-memory ModelContainer: \(error)")
            }
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            // Повторная попытка с чистой конфигурацией.
            do {
                modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
            } catch {
                // Крайний случай: in-memory контейнер, чтобы приложение не падало.
                do {
                    modelContainer = try ModelContainer(
                        for: schema,
                        configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    )
                } catch {
                    fatalError("Не удалось создать ModelContainer: \(error)")
                }
            }
        }
    }

    var context: ModelContext { modelContainer.mainContext }

    // MARK: - CRUD

    @discardableResult
    func createNote(title: String = "", text: String = "") -> Note {
        let note = Note(title: title, text: text)
        context.insert(note)
        save()
        return note
    }

    @discardableResult
    func save() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    /// Все заметки, опционально включая архив.
    func fetchNotes(includeArchived: Bool = false) -> [Note] {
        do {
            if includeArchived {
                return try context.fetch(FetchDescriptor<Note>())
            }
            return try context.fetch(FetchDescriptor<Note>(predicate: #Predicate { !$0.isArchived }))
        } catch {
            return []
        }
    }

    func fetchArchivedNotes() -> [Note] {
        do {
            return try context.fetch(FetchDescriptor<Note>(predicate: #Predicate { $0.isArchived }))
        } catch {
            return []
        }
    }

    /// Поиск по заголовку и содержимому, без учёта регистра.
    /// Фильтрация выполняется в памяти — надёжно для любых Unicode-строк.
    func searchNotes(query: String, includeArchived: Bool = false) -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fetchNotes(includeArchived: includeArchived) }
        let lowered = trimmed.lowercased()
        return fetchNotes(includeArchived: includeArchived).filter { note in
            note.title.lowercased().contains(lowered) || note.text.lowercased().contains(lowered)
        }
    }

    func delete(_ note: Note) {
        context.delete(note)
        save()
    }

    func setPinned(_ note: Note, pinned: Bool) {
        note.isPinned = pinned
        note.updatedAt = .now
        save()
    }

    func togglePinned(_ note: Note) {
        setPinned(note, pinned: !note.isPinned)
    }

    func setArchived(_ note: Note, archived: Bool) {
        note.isArchived = archived
        note.updatedAt = .now
        save()
    }

    func archive(_ note: Note) { setArchived(note, archived: true) }
    func restore(_ note: Note) { setArchived(note, archived: false) }

    /// Дублирует заметку: новый UUID, новые даты, «Копия» в заголовке.
    @discardableResult
    func duplicate(_ note: Note) -> Note {
        let copy = note.makeDuplicate()
        context.insert(copy)
        save()
        return copy
    }

    /// Обновляет содержимое заметки и пересчитывает статистику.
    /// Возвращает true при успешном сохранении.
    @discardableResult
    func updateContent(of note: Note, title: String, text: String) -> Bool {
        note.title = title
        note.text = text
        note.refreshStatistics()
        return save()
    }
}
