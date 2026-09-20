// File: Pishi/Models/Note.swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool
    var sortIndex: Int
    var wordCount: Int
    var characterCount: Int

    init(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        isArchived: Bool = false,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.sortIndex = sortIndex
        self.wordCount = text.computedWordCount
        self.characterCount = text.count
    }

    // MARK: - Computed helpers

    /// Заголовок для отображения: если пустой — берём первые слова текста, иначе «Без названия».
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstWords = text
            .split(whereSeparator: \.isWhitespace)
            .prefix(5)
            .joined(separator: " ")
        return firstWords.isEmpty ? Constants.Strings.untitled : firstWords
    }

    /// Превью текста для карточки.
    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Constants.Strings.emptyNote : String(trimmed.prefix(200))
    }

    var lineCount: Int { text.computedLineCount }
    var computedWordCount: Int { text.computedWordCount }

    /// Пересчитывает статистику и обновляет updatedAt.
    func refreshStatistics(touchDate: Bool = true) {
        wordCount = text.computedWordCount
        characterCount = text.count
        if touchDate { updatedAt = .now }
    }

    /// Создаёт копию заметки с новым UUID, заголовком «… (Копия)» и свежими датами.
    func makeDuplicate() -> Note {
        let copyTitle = title.isEmpty
            ? Constants.Strings.copySuffix
            : "\(title) (\(Constants.Strings.copySuffix))"
        return Note(
            id: UUID(),
            title: copyTitle,
            text: text,
            createdAt: .now,
            updatedAt: .now,
            isPinned: false,
            isArchived: isArchived,
            sortIndex: sortIndex
        )
    }

    /// Экспорт в Markdown.
    var markdownContent: String {
        var result = ""
        if !displayTitle.isEmpty {
            result += "# \(displayTitle)\n\n"
        }
        result += text
        return result
    }

    /// Экспорт в TXT.
    var plainTextContent: String {
        var result = ""
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result += title + "\n\n"
        }
        result += text
        return result
    }
}
