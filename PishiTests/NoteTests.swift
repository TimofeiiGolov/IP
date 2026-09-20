// File: PishiTests/NoteTests.swift
import XCTest
@testable import Pishi

final class NoteTests: XCTestCase {

    func testNewNoteDefaults() {
        let note = Note()
        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.text, "")
        XCTAssertFalse(note.isPinned)
        XCTAssertFalse(note.isArchived)
        XCTAssertEqual(note.wordCount, 0)
        XCTAssertEqual(note.characterCount, 0)
    }

    func testWordCount() {
        let note = Note(text: "привет мир как дела")
        XCTAssertEqual(note.computedWordCount, 4)
    }

    func testWordCountEmpty() {
        let note = Note(text: "")
        XCTAssertEqual(note.computedWordCount, 0)
        let spaces = Note(text: "   \n\t ")
        XCTAssertEqual(spaces.computedWordCount, 0)
    }

    func testCharacterCount() {
        let note = Note(text: "абвгд")
        XCTAssertEqual(note.characterCount, 5)
    }

    func testLineCount() {
        let note = Note(text: "строка1\nстрока2\nстрока3")
        XCTAssertEqual(note.lineCount, 3)
        let empty = Note(text: "")
        XCTAssertEqual(empty.lineCount, 0)
    }

    func testDisplayTitleFallsBackToFirstWords() {
        let note = Note(title: "", text: "первое второе третье четвёртое пятое шестое")
        XCTAssertEqual(note.displayTitle, "первое второе третье четвёртое пятое")
    }

    func testDisplayTitleUntitledWhenEmpty() {
        let note = Note(title: "", text: "")
        XCTAssertEqual(note.displayTitle, Constants.Strings.untitled)
    }

    func testDisplayTitleUsesTitleWhenPresent() {
        let note = Note(title: "Моя заметка", text: "текст")
        XCTAssertEqual(note.displayTitle, "Моя заметка")
    }

    func testPreviewEmptyNote() {
        let note = Note(text: "")
        XCTAssertEqual(note.preview, Constants.Strings.emptyNote)
    }

    func testPreviewTruncates() {
        let long = String(repeating: "а", count: 500)
        let note = Note(text: long)
        XCTAssertEqual(note.preview.count, 200)
    }

    func testRefreshStatisticsUpdatesCountsAndDate() {
        let note = Note(text: "раз")
        let oldDate = note.updatedAt
        note.text = "раз два три"
        note.refreshStatistics()
        XCTAssertEqual(note.wordCount, 3)
        XCTAssertEqual(note.characterCount, "раз два три".count)
        XCTAssertGreaterThanOrEqual(note.updatedAt, oldDate)
    }

    func testRefreshStatisticsWithoutTouchingDate() {
        let note = Note(text: "раз")
        let date = note.updatedAt
        note.text = "раз два"
        note.refreshStatistics(touchDate: false)
        XCTAssertEqual(note.updatedAt, date)
        XCTAssertEqual(note.wordCount, 2)
    }

    func testMakeDuplicate() {
        let original = Note(title: "Оригинал", text: "текст", isPinned: true)
        let copy = original.makeDuplicate()
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.title, "Оригинал (Копия)")
        XCTAssertEqual(copy.text, "текст")
        XCTAssertFalse(copy.isPinned)
        XCTAssertGreaterThanOrEqual(copy.createdAt, original.createdAt)
    }

    func testMakeDuplicateUntitled() {
        let original = Note(title: "", text: "текст")
        let copy = original.makeDuplicate()
        XCTAssertEqual(copy.title, Constants.Strings.copySuffix)
    }

    func testMarkdownContent() {
        let note = Note(title: "Заголовок", text: "тело")
        XCTAssertEqual(note.markdownContent, "# Заголовок\n\nтело")
    }

    func testPlainTextContent() {
        let note = Note(title: "Заголовок", text: "тело")
        XCTAssertEqual(note.plainTextContent, "Заголовок\n\nтело")
    }

    func testPlainTextContentEmptyTitle() {
        let note = Note(title: "", text: "тело")
        XCTAssertEqual(note.plainTextContent, "тело")
    }
}
