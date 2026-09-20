// File: Pishi/Views/Components/SearchBar.swift
import SwiftUI

/// Панель поиска внутри заметки: поле, следующее/предыдущее совпадение, счётчик, закрытие.
struct InNoteSearchBar: View {
    @Binding var query: String
    let matchCount: Int
    let currentMatchIndex: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(String(localized: "Найти в заметке"), text: $query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit(onNext)

            if !query.isEmpty {
                Text(matchCount == 0
                     ? String(localized: "Нет совпадений")
                     : "\(currentMatchIndex + 1)/\(matchCount)")
                    .font(.caption)
                    .foregroundStyle(matchCount == 0 ? .red : .secondary)
                    .monospacedDigit()
            }

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .disabled(matchCount == 0)
            .accessibilityLabel(String(localized: "Предыдущее совпадение"))

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .disabled(matchCount == 0)
            .accessibilityLabel(String(localized: "Следующее совпадение"))

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(String(localized: "Закрыть поиск"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .frame(minHeight: Constants.Layout.minimumTouchTarget)
    }
}

#Preview {
    InNoteSearchBar(query: .constant("текст"), matchCount: 3, currentMatchIndex: 1,
                    onNext: {}, onPrevious: {}, onClose: {})
}
