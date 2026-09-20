// File: Pishi/Views/NoteGridItemView.swift
import SwiftUI

/// Карточка заметки в режиме сетки.
struct NoteGridItemView: View {
    let note: Note
    var showWordCount: Bool = true
    var showCharacterCount: Bool = true
    var showArchiveBadge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                if showArchiveBadge && note.isArchived {
                    Image(systemName: "archivebox.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            Text(note.displayTitle)
                .font(.headline)
                .lineLimit(2)

            Text(note.preview)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
                if showWordCount {
                    Text("\(note.wordCount)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "Слов: \(note.wordCount)"))
                }
                if showCharacterCount {
                    Text("\(note.characterCount)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "Символов: \(note.characterCount)"))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NoteGridItemView(note: Note(title: "Пример", text: "Текст заметки"))
        .padding()
}
