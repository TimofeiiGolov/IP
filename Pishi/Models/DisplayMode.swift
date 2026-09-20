// File: Pishi/Models/DisplayMode.swift
import Foundation

enum DisplayMode: String, CaseIterable, Identifiable, Codable {
    case list
    case grid

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .list: return String(localized: "Список")
        case .grid: return String(localized: "Сетка")
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }

    var toggled: DisplayMode {
        self == .list ? .grid : .list
    }
}
