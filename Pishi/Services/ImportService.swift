import Foundation
import UniformTypeIdentifiers

/// Импорт текстовых файлов (TXT, Markdown, UTF-8) через fileImporter.
struct ImportService {
    /// Результат импорта: заголовок (имя файла без расширения) и текст.
    struct ImportedNote {
        let title: String
        let text: String
    }

    enum ImportError: LocalizedError {
        case accessDenied
        case unsupportedFormat
        case readFailed
        case invalidEncoding

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Нет доступа к файлу. Разрешите доступ и попробуйте снова."
            case .unsupportedFormat:
                return "Неподдерживаемый формат. Можно импортировать TXT и Markdown."
            case .readFailed:
                return "Не удалось прочитать файл."
            case .invalidEncoding:
                return "Файл должен быть в кодировке UTF-8."
            }
        }
    }

    static let allowedContentTypes: [UTType] = [.plainText, .utf8PlainText, .text, .init(filenameExtension: "md") ?? .plainText]

    /// Читает файл по URL из fileImporter.
    /// securityScopedResource обязателен для файлов, выбранных пользователем.
    static func importNote(from url: URL) throws -> ImportedNote {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let ext = url.pathExtension.lowercased().isEmpty ? nil : url.pathExtension.lowercased(),
              ["txt", "md", "markdown", "text"].contains(ext) || isPlainText(url) else {
            throw ImportError.unsupportedFormat
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.readFailed
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidEncoding
        }

        let title = url.deletingPathExtension().lastPathComponent
        return ImportedNote(title: title, text: text)
    }

    /// Проверяет, является ли файл текстовым по UTI.
    private static func isPlainText(_ url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let contentType = resourceValues.contentType else {
            return false
        }
        return contentType.conforms(to: .plainText) || contentType.conforms(to: .text)
    }
}
