// File: PishiTests/NoteEditorViewModelTests.swift
import XCTest
import SwiftData
@testable import Pishi

@MainActor
final class NoteEditorViewModelTests: XCTestCase {
    private var persistence: PersistenceController!

    override func setUp() async throws {
        persistence = PersistenceController(inMemory: true)
    }

    override func tearDown() async throws {
        persistence = nil
    }

    private func makeViewModel(title: String = "", text: String = "") -> (NoteEditorViewModel, Note) {
        let note = Note(title: title, text: text)
        persistence.context.insert(note)
        persistence.save()
        let vm = NoteEditorViewModel(note: note, persistence: persistence, autosaveInterval: 0.05)
        return (vm, note)
    }

    func testInitialStateMatchesNote() {
        let (vm, note) = makeViewModel(title: "Заголовок", text: "Текст")
        XCTAssertEqual(vm.title, note.title)
        XCTAssertEqual(vm.text, note.text)
    }

    func testSaveNowPersistsContent() {
        let (vm, note) = makeViewModel()
        vm.title = "Новый"
        vm.text = "Новый текст"
        vm.contentChanged()
        vm.saveNow()

        XCTAssertEqual(note.title, "Новый")
        XCTAssertEqual(note.text, "Новый текст")
        XCTAssertEqual(note.wordCount, 2)
        XCTAssertEqual(note.characterCount, "Новый текст".count)
    }

    func testDebouncedAutosave() async {
        let (vm, note) = makeViewModel()
        vm.text = "дебounce"
        vm.contentChanged()

        // Сразу после изменения сохранение ещё не произошло.
        XCTAssertEqual(note.text, "")

        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(note.text, "дебounce")
    }

    func testSaveStatusTransitions() {
        let (vm, _) = makeViewModel()
        vm.text = "x"
        vm.contentChanged()
        XCTAssertEqual(vm.saveStatus, .saving)

        vm.saveNow()
        if case .saved = vm.saveStatus {} else {
            XCTFail("Ожидался статус .saved")
        }
    }

    func testStatisticsUpdateLive() {
        let (vm, _) = makeViewModel()
        vm.text = "раз два три\nчетыре"
        XCTAssertEqual(vm.wordCount, 4)
        XCTAssertEqual(vm.lineCount, 2)
        XCTAssertEqual(vm.characterCount, vm.text.count)
    }

    func testCleanupEmptyNoteDeletesIt() {
        let (vm, note) = makeViewModel()
        let id = note.id
        vm.cleanupEmptyNoteIfNeeded()

        let remaining = persistence.fetchNotes()
        XCTAssertFalse(remaining.contains { $0.id == id })
    }

    func testCleanupKeepsNonEmptyNote() {
        let (vm, note) = makeViewModel()
        vm.text = "важный текст"
        vm.cleanupEmptyNoteIfNeeded()

        let remaining = persistence.fetchNotes()
        XCTAssertTrue(remaining.contains { $0.id == note.id })
        XCTAssertEqual(remaining.first?.text, "важный текст")
    }

    func testInNoteSearchMatches() {
        let (vm, _) = makeViewModel(text: "кот и кот и собака")
        vm.inNoteSearchQuery = "кот"
        XCTAssertEqual(vm.matchCount, 2)

        vm.nextMatch()
        XCTAssertEqual(vm.currentMatchIndex, 1)
        vm.nextMatch()
        XCTAssertEqual(vm.currentMatchIndex, 0)
        vm.previousMatch()
        XCTAssertEqual(vm.currentMatchIndex, 1)
    }

    func testInNoteSearchCaseInsensitive() {
        let (vm, _) = makeViewModel(text: "Привет мир")
        vm.inNoteSearchQuery = "ПРИВЕТ"
        XCTAssertEqual(vm.matchCount, 1)
    }

    func testInNoteSearchNoMatches() {
        let (vm, _) = makeViewModel(text: "текст")
        vm.inNoteSearchQuery = "нету"
        XCTAssertEqual(vm.matchCount, 0)
        XCTAssertNil(vm.currentMatchRange)
    }

    func testCloseSearchResetsState() {
        let (vm, _) = makeViewModel(text: "кот")
        vm.isSearchVisible = true
        vm.inNoteSearchQuery = "кот"
        vm.closeSearch()
        XCTAssertFalse(vm.isSearchVisible)
        XCTAssertTrue(vm.inNoteSearchQuery.isEmpty)
        XCTAssertEqual(vm.currentMatchIndex, 0)
    }

    func testTogglePinAndArchive() {
        let (vm, note) = makeViewModel()
        vm.togglePin()
        XCTAssertTrue(note.isPinned)
        vm.toggleArchive()
        XCTAssertTrue(note.isArchived)
    }

    func testDuplicateReturnsOpenedCopy() {
        let (vm, note) = makeViewModel(title: "Оригинал", text: "содержимое")
        vm.title = "Оригинал"
        vm.text = "содержимое"
        let copy = vm.duplicate()

        XCTAssertNotEqual(copy.id, note.id)
        XCTAssertEqual(copy.text, "содержимое")
        XCTAssertTrue(copy.title.contains(Constants.Strings.copySuffix))
    }

    func testDeleteNoteRemovesFromStore() {
        let (vm, note) = makeViewModel(text: "удали меня")
        let id = note.id
        vm.deleteNote()
        XCTAssertFalse(persistence.fetchNotes().contains { $0.id == id })
    }

    func testExportURLCreatesFile() throws {
        let (vm, _) = makeViewModel(title: "Экспорт", text: "тело заметки")
        let url = try vm.exportURL(format: .txt)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("тело заметки"))
        try? FileManager.default.removeItem(at: url)
    }

    func testExportMarkdownContainsHeading() throws {
        let (vm, _) = makeViewModel(title: "Заголовок", text: "текст")
        let url = try vm.exportURL(format: .markdown)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("# Заголовок"))
        try? FileManager.default.removeItem(at: url)
    }
}
