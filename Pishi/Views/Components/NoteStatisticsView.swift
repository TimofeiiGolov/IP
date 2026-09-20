// File: Pishi/Views/Components/NoteStatisticsView.swift
import SwiftUI

/// Статистика заметки: слова, символы, строки, время изменения.
struct NoteStatisticsView: View {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int
    let updatedAt: Date
    var showWordCount: Bool = true
    var showCharacterCount: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            if showWordCount {
                statItem(value: "\(wordCount)", label: Constants.Strings.words)
            }
            if showCharacterCount {
                statItem(value: "\(characterCount)", label: Constants.Strings.characters)
            }
            statItem(value: "\(lineCount)", label: Constants.Strings.lines)
            Spacer()
            Text(updatedAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private func statItem(value: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(value).fontWeight(.semibold)
            Text(label)
        }
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if showWordCount { parts.append("\(wordCount) \(Constants.Strings.words.lowercased())") }
        if showCharacterCount { parts.append("\(characterCount) \(Constants.Strings.characters.lowercased())") }
        parts.append("\(lineCount) \(Constants.Strings.lines.lowercased())")
        return parts.joined(separator: ", ")
    }
}

#Preview {
    NoteStatisticsView(wordCount: 128, characterCount: 743, lineCount: 24, updatedAt: .now)
}
