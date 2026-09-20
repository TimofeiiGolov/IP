// File: Pishi/Models/SortOption.swift
import Foundation

enum SortOption: String, CaseIterable, Identifiable, Codable {
    case updatedDate
    case createdDate
    case title
    case pinnedFirst
    case newestFirst
    case oldestFirst

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .updatedDate: return String(localized: "Сортировка: по изменению")
        case .createdDate: return String(localized: "Сортировка: по созданию")
        case .title: return String(localized: "Сортировка: по названию")
        case .pinnedFirst: return String(localized: "Сначала закреплённые")
        case .newestFirst: return String(localized: "Сначала новые")
        case .oldestFirst: return String(localized: "Сначала старые")
        }
    }

    var systemImage: String {
        switch self {
        case .updatedDate: return "clock.arrow.circlepath"
        case .createdDate: return "calendar"
        case .title: return "textformat"
        case .pinnedFirst: return "pin"
        case .newestFirst: return "arrow.down.circle"
        case .oldestFirst: return "arrow.up.circle"
        }
    }

    /// Сравнивает две заметки согласно выбранному режиму.
    func compare(_ lhs: Note, _ rhs: Note) -> Bool {
        switch self {
        case .updatedDate:
            return lhs.updatedAt > rhs.updatedAt
        case .createdDate:
            return lhs.createdAt > rhs.createdAt
        case .title:
            return lhs.displayTitle.localizedStandardCompare(rhs.displayTitle) == .orderedAscending
        case .pinnedFirst:
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.updatedAt > rhs.updatedAt
        case .newestFirst:
            return lhs.createdAt > rhs.createdAt
        case .oldestFirst:
            return lhs.createdAt < rhs.createdAt
        }
    }
}
