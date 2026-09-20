// File: Pishi/Services/ExportService.swift
import Foundation
import UniformTypeIdentifiers

/// Экспорт заметки в TXT или Markdown: создаёт временный файл для Share Sheet.
struct ExportService {
    enum ExportFormat: String, CaseIterable, Identifiable {
        case txt = "TXT"
        case markdown = "Markdown"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .txt: return "txt"
            case .markdown: return "md"
            }
        }

        var contentType: UTType {
            switch self {
            case .txt: return .plainText
            case .markdown: return UTType(filenameExtension: "md") ?? .plainText
            }
        }
    }

    enum ExportError: LocalizedError {
        case encodingFailed
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Не удалось сохранить файл: ошибка кодирования."
            case .writeFailed:
                return "Не удалось записать файл на диск."
            }
        }
    }

    /// Создаёт временный файл для экспорта и возвращает его URL.
    static func exportFile(title: String, text: String, format: ExportFormat) throws -> URL {
        let safeTitle = sanitizeFileName(title)
        let fileName = "\(safeTitle).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let content: String
        switch format {
        case .txt:
            content = plainTextContent(title: title, text: text)
        case .markdown:
            content = markdownContent(title: title, text: text)
        }

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ExportError.writeFailed
        }
        return url
    }

    /// Формирует Markdown-документ: заголовок + текст.
    static func markdownContent(title: String, text: String) -> String {
        let heading = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Constants.Strings.untitled
            : title
        return "# \(heading)\n\n\(text)\n"
    }

    /// Формирует TXT-документ: заголовок + текст.
    static func plainTextContent(title: String, text: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return text }
        return "\(trimmed)\n\n\(text)"
    }

    /// Убирает из имени файла символы, недопустимые в именах файлов.
    static func sanitizeFileName(_ name: String) -> String {
        name.safeFileName
    }
}
