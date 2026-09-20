// File: Pishi/Models/NoteFilter.swift
import Foundation

enum NoteFilter: String, CaseIterable, Identifiable, Codable {
    case all
    case pinned
    case archive
    case recentlyEdited

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .all: return String(localized: "Все заметки")
        case .pinned: return String(localized: "Закреплённые")
        case .archive: return String(localized: "Архив")
        case .recentlyEdited: return String(localized: "Недавно изменённые")
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .pinned: return "pin.fill"
        case .archive: return "archivebox"
        case .recentlyEdited: return "clock"
        }
    }

    /// Проверяет, подходит ли заметка под фильтр.
    func matches(_ note: Note) -> Bool {
        switch self {
        case .all:
            return !note.isArchived
        case .pinned:
            return note.isPinned && !note.isArchived
        case .archive:
            return note.isArchived
        case .recentlyEdited:
            return !note.isArchived
                && note.updatedAt > Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        }
    }
}
