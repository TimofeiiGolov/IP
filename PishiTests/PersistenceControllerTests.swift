// File: PishiTests/PersistenceControllerTests.swift
import XCTest
import SwiftData
@testable import Pishi

@MainActor
final class PersistenceControllerTests: XCTestCase {

    private var controller: PersistenceController!

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }

    func testCreateNote() {
        let note = controller.createNote(title: "Тест", text: "содержимое")
        XCTAssertEqual(note.title, "Тест")
        XCTAssertEqual(note.text, "содержимое")
        XCTAssertEqual(controller.fetchNotes().count, 1)
    }

    func testSaveAndFetch() {
        controller.createNote(title: "A", text: "a")
        controller.createNote(title: "B", text: "b")
        let fetched = controller.fetchNotes()
        XCTAssertEqual(fetched.count, 2)
    }

    func testFetchExcludesArchivedByDefault() {
        let a = controller.createNote(title: "A")
        let b = controller.createNote(title: "B")
        controller.archive(b)
        XCTAssertEqual(controller.fetchNotes().count, 1)
        XCTAssertEqual(controller.fetchNotes().first?.title, "A")
        XCTAssertEqual(controller.fetchArchivedNotes().count, 1)
        XCTAssertEqual(controller.fetchArchivedNotes().first?.title, "B")
        _ = a
    }

    func testDelete() {
        let note = controller.createNote(title: "Удалить")
        controller.delete(note)
        XCTAssertEqual(controller.fetchNotes().count, 0)
    }

    func testPinAndUnpin() {
        let note = controller.createNote(title: "Закрепить")
        controller.setPinned(note, pinned: true)
        XCTAssertTrue(note.isPinned)
        controller.togglePinned(note)
        XCTAssertFalse(note.isPinned)
    }

    func testArchiveAndRestore() {
        let note = controller.createNote(title: "Архив")
        controller.archive(note)
        XCTAssertTrue(note.isArchived)
        controller.restore(note)
        XCTAssertFalse(note.isArchived)
    }

    func testDuplicate() {
        let note = controller.createNote(title: "Оригинал", text: "текст")
        let copy = controller.duplicate(note)
        XCTAssertNotEqual(copy.id, note.id)
        XCTAssertEqual(copy.text, "текст")
        XCTAssertTrue(copy.title.contains("Копия"))
        XCTAssertEqual(controller.fetchNotes().count, 2)
    }

    func testUpdateContentUpdatesDateAndCounts() {
        let note = controller.createNote(title: "Старый", text: "старый текст")
        let oldDate = note.updatedAt
        try? awaitTaskSleep()
        let ok = controller.updateContent(of: note, title: "Новый", text: "новый текст длиннее")
        XCTAssertTrue(ok)
        XCTAssertEqual(note.title, "Новый")
        XCTAssertEqual(note.wordCount, 3)
        XCTAssertGreaterThanOrEqual(note.updatedAt, oldDate)
    }

    func testSearchByTitle() {
        controller.createNote(title: "Рецепт борща", text: "")
        controller.createNote(title: "Список дел", text: "")
        let results = controller.searchNotes(query: "борщ")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Рецепт борща")
    }

    func testSearchByContent() {
        controller.createNote(title: "Заметка", text: "встреча в понедельник")
        controller.createNote(title: "Другая", text: "купить молоко")
        let results = controller.searchNotes(query: "понедельник")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Заметка")
    }

    func testSearchCaseInsensitive() {
        controller.createNote(title: "Тест", text: "Hello World")
        XCTAssertEqual(controller.searchNotes(query: "hello").count, 1)
        XCTAssertEqual(controller.searchNotes(query: "WORLD").count, 1)
    }

    func testSearchEmptyQueryReturnsAll() {
        controller.createNote(title: "A")
        controller.createNote(title: "B")
        XCTAssertEqual(controller.searchNotes(query: "").count, 2)
        XCTAssertEqual(controller.searchNotes(query: "   ").count, 2)
    }

    func testSearchNoResults() {
        controller.createNote(title: "A", text: "a")
        XCTAssertEqual(controller.searchNotes(query: "xyz").count, 0)
    }

    func testEmptyDatabase() {
        XCTAssertEqual(controller.fetchNotes().count, 0)
        XCTAssertEqual(controller.fetchArchivedNotes().count, 0)
        XCTAssertEqual(controller.searchNotes(query: "что угодно").count, 0)
    }

    private func awaitTaskSleep() throws {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2)
    }
}
