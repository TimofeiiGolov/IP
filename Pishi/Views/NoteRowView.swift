// File: Pishi/Views/NoteRowView.swift
import SwiftUI

/// Карточка заметки в режиме списка.
struct NoteRowView: View {
    let note: Note
    var showWordCount: Bool = true
    var showCharacterCount: Bool = true
    var showArchiveBadge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .accessibilityLabel(String(localized: "Закреплено"))
                }
                if showArchiveBadge && note.isArchived {
                    Image(systemName: "archivebox.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(String(localized: "В архиве"))
                }
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text(note.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if showWordCount {
                    Label("\(note.wordCount)", systemImage: "text.word.spacing")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "Слов: \(note.wordCount)"))
                }
                if showCharacterCount {
                    Label("\(note.characterCount)", systemImage: "character.cursor.ibeam")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "Символов: \(note.characterCount)"))
                }
            }
        }
        .padding(.vertical, 2)
        .frame(minHeight: Constants.Layout.minimumTouchTarget)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        NoteRowView(note: Note(title: "Пример", text: "Текст заметки для превью"))
    }
}
