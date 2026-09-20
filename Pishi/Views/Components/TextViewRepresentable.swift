// File: Pishi/Views/Components/TextViewRepresentable.swift
import SwiftUI
import UIKit

/// Слабая ссылка на UITextView для команд Undo/Redo из тулбара.
@MainActor
final class TextViewHolder {
    weak var textView: UITextView?
}

/// Обёртка UITextView: полноценный first responder, выделение, copy/paste,
/// undo/redo, длинный текст, подсветка совпадений поиска.
struct TextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var isScrollEnabled: Bool = true
    var autoFocus: Bool = false
    var lineWrapping: Bool = true
    var searchQuery: String = ""
    var currentMatchRange: NSRange?
    var onEditing: () -> Void
    let holder: TextViewHolder

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.isScrollEnabled = isScrollEnabled
        textView.alwaysBounceVertical = isScrollEnabled
        textView.allowsEditingTextAttributes = false
        textView.autocorrectionType = .default
        textView.keyboardDismissMode = .interactive
        textView.accessibilityIdentifier = Constants.Accessibility.bodyField
        holder.textView = textView
        textView.text = text
        applyHighlights(to: textView)
        if autoFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textView.becomeFirstResponder()
            }
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        if textView.text != text && !textView.isFirstResponder {
            textView.text = text
        }
        textView.font = font
        textView.isScrollEnabled = isScrollEnabled
        textView.textContainer.lineBreakMode = lineWrapping ? .byWordWrapping : .byCharWrapping
        applyHighlights(to: textView)
    }

    /// Подсветка совпадений поиска: все совпадения жёлтым, текущее — оранжевым.
    private func applyHighlights(to textView: UITextView) {
        guard !searchQuery.isEmpty else {
            if textView.typingAttributes[.backgroundColor] != nil {
                textView.typingAttributes.removeValue(forKey: .backgroundColor)
            }
            textView.attributedText = NSAttributedString(
                string: textView.text,
                attributes: [.font: font, .foregroundColor: UIColor.label]
            )
            return
        }
        let fullText = textView.text ?? ""
        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [.font: font, .foregroundColor: UIColor.label]
        )
        let nsQuery = searchQuery as NSString
        var searchLocation = 0
        let lowercasedFull = fullText.lowercased() as NSString
        let lowercasedQuery = searchQuery.lowercased()
        while searchLocation < lowercasedFull.length {
            let found = lowercasedFull.range(
                of: lowercasedQuery,
                options: [],
                range: NSRange(location: searchLocation, length: lowercasedFull.length - searchLocation)
            )
            if found.location == NSNotFound { break }
            attributed.addAttribute(
                .backgroundColor,
                value: UIColor.systemYellow.withAlphaComponent(0.4),
                range: found
            )
            if let current = currentMatchRange, NSEqualRanges(current, found) {
                attributed.addAttribute(
                    .backgroundColor,
                    value: UIColor.systemOrange.withAlphaComponent(0.7),
                    range: found
                )
            }
            searchLocation = found.location + max(found.length, 1)
        }
        let selectedRange = textView.selectedRange
        textView.attributedText = attributed
        textView.selectedRange = selectedRange
        _ = nsQuery
        if let current = currentMatchRange {
            textView.scrollRangeToVisible(current)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewRepresentable

        init(_ parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onEditing()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onEditing()
        }
    }
}
