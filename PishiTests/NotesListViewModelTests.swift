// File: PishiTests/NotesListViewModelTests.swift
import XCTest
import SwiftData
@testable import Pishi

@MainActor
final class NotesListViewModelTests: XCTestCase {
    private var persistence: PersistenceController!
    private var viewModel: NotesListViewModel!

    override func setUp() async throws {
        persistence = PersistenceController(inMemory: true)
        viewModel = NotesListViewModel(persistence: persistence)
        viewModel.load()
    }

    override func tearDown() async throws {
        viewModel = nil
        persistence = nil
    }

    func testEmptyStateInitially() {
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.isSearchEmpty)
    }

    func testCreateNoteAppearsInList() {
        let note = viewModel.createNote()
        XCTAssertFalse(viewModel.notes.isEmpty)
        XCTAssertTrue(viewModel.notes.contains { $0.id == note.id })
    }

    func testSearchByTitleCaseInsensitive() {
        let note = Note(title: "Привет Мир", text: "")
        persistence.context.insert(note)
        persistence.save()

        viewModel.searchText = "привет"
        viewModel.load()
        XCTAssertEqual(viewModel.notes.count, 1)

        viewModel.searchText = "МИР"
        viewModel.load()
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testSearchByContent() {
        let note = Note(title: "", text: "содержимое для поиска")
        persistence.context.insert(note)
        persistence.save()

        viewModel.searchText = "поиска"
        viewModel.load()
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testEmptySearchQueryShowsAll() {
        persistence.context.insert(Note(title: "A", text: "a"))
        persistence.context.insert(Note(title: "B", text: "b"))
        persistence.save()

        viewModel.searchText = "   "
        viewModel.load()
        XCTAssertEqual(viewModel.notes.count, 2)
    }

    func testSearchNoResults() {
        persistence.context.insert(Note(title: "A", text: "a"))
        persistence.save()

        viewModel.searchText = "неттакого"
        viewModel.load()
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertTrue(viewModel.isSearchEmpty)
    }

    func testPinnedNotesComeFirst() {
        let first = Note(title: "Первая", text: "1")
        let second = Note(title: "Вторая", text: "2", isPinned: true)
        persistence.context.insert(first)
        persistence.context.insert(second)
        persistence.save()

        viewModel.sortOption = .pinnedFirst
        viewModel.load()
        XCTAssertEqual(viewModel.pinnedNotes.count, 1)
        XCTAssertEqual(viewModel.pinnedNotes.first?.id, second.id)
    }

    func testTogglePin() {
        let note = viewModel.createNote()
        XCTAssertFalse(note.isPinned)

        viewModel.togglePin(note)
        XCTAssertTrue(note.isPinned)

        viewModel.togglePin(note)
        XCTAssertFalse(note.isPinned)
    }

    func testArchiveAndRestore() {
        let note = viewModel.createNote()
        viewModel.archive(note)
        XCTAssertTrue(note.isArchived)
        XCTAssertFalse(viewModel.notes.contains { $0.id == note.id })

        viewModel.filter = .archive
        viewModel.load()
        XCTAssertTrue(viewModel.notes.contains { $0.id == note.id })

        viewModel.restore(note)
        XCTAssertFalse(note.isArchived)
    }

    func testDeleteWithUndo() {
        let note = viewModel.createNote()
        let noteID = note.id

        viewModel.delete(note)
        XCTAssertFalse(viewModel.notes.contains { $0.id == noteID })
        XCTAssertTrue(viewModel.showUndoBanner)

        viewModel.undoDelete()
        XCTAssertTrue(viewModel.notes.contains { $0.id == noteID })
        XCTAssertFalse(viewModel.showUndoBanner)
    }

    func testDuplicateCreatesCopy() {
        let note = Note(title: "Оригинал", text: "текст")
        persistence.context.insert(note)
        persistence.save()

        let copy = viewModel.duplicate(note)
        XCTAssertNotEqual(copy.id, note.id)
        XCTAssertEqual(copy.text, note.text)
        XCTAssertTrue(copy.title.contains(Constants.Strings.copySuffix))
    }

    func testSortByTitle() {
        persistence.context.insert(Note(title: "Б", text: ""))
        persistence.context.insert(Note(title: "А", text: ""))
        persistence.save()

        viewModel.sortOption = .title
        viewModel.load()
        XCTAssertEqual(viewModel.notes.first?.title, "А")
    }

    func testSortOldestFirst() {
        let old = Note(title: "Старая", text: "", createdAt: Date(timeIntervalSince1970: 1000))
        let new = Note(title: "Новая", text: "", createdAt: Date(timeIntervalSince1970: 2000))
        persistence.context.insert(old)
        persistence.context.insert(new)
        persistence.save()

        viewModel.sortOption = .oldestFirst
        viewModel.load()
        XCTAssertEqual(viewModel.notes.first?.title, "Старая")
    }

    func testFilterRecentlyEdited() {
        let recent = Note(title: "Свежая", text: "", updatedAt: .now)
        let stale = Note(title: "Старая", text: "",
                         updatedAt: Calendar.current.date(byAdding: .day, value: -30, to: .now)!)
        persistence.context.insert(recent)
        persistence.context.insert(stale)
        persistence.save()

        viewModel.filter = .recentlyEdited
        viewModel.load()
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "Свежая")
    }

    func testApplySettings() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: "vm-tests-\(UUID().uuidString)")!)
        settings.displayMode = .grid
        settings.defaultSort = .title

        viewModel.applySettings(settings)
        XCTAssertEqual(viewModel.displayMode, .grid)
        XCTAssertEqual(viewModel.sortOption, .title)
    }
}
