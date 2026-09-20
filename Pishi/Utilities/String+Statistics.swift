// File: Pishi/Utilities/String+Statistics.swift
import Foundation

extension String {
    /// Количество слов (последовательности непробельных символов).
    var computedWordCount: Int {
        split(whereSeparator: \.isWhitespace).count
    }

    /// Количество строк. Пустая строка = 0 строк.
    var computedLineCount: Int {
        guard !isEmpty else { return 0 }
        var count = 0
        enumerateLines { _, _ in count += 1 }
        return count
    }

    /// Количество символов (Unicode grapheme clusters).
    var computedCharacterCount: Int { count }

    /// Короткое превью из первых N символов.
    func preview(maxLength: Int = 200) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        return String(trimmed.prefix(maxLength)) + "…"
    }

    /// Безопасное имя файла из строки (для экспорта).
    var safeFileName: String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:.")
        let cleaned = components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "note" : String(cleaned.prefix(80))
    }
}
