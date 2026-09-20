// File: PishiUITests/PishiUITests.swift
import XCTest

final class PishiUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Главный экран

    func testMainScreenIsDisplayed() throws {
        let title = app.navigationBars["Заметки"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Главный экран должен отображаться")
        XCTAssertTrue(app.buttons[Constants.Accessibility.newNoteButton].exists)
    }

    // MARK: - Создание заметки

    func testCreateNoteAndType() throws {
        app.buttons[Constants.Accessibility.newNoteButton].tap()

        let titleField = app.textFields[Constants.Accessibility.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10), "Редактор должен открыться")
        titleField.tap()
        titleField.typeText("Тестовая заметка")

        let bodyField = app.textViews[Constants.Accessibility.bodyField]
        XCTAssertTrue(bodyField.waitForExistence(timeout: 5))
        bodyField.tap()
        bodyField.typeText("Привет, мир!")

        // Возврат к списку
        app.buttons[Constants.Accessibility.backButton].tap()

        let list = app.navigationBars["Заметки"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Тестовая заметка"].waitForExistence(timeout: 5),
                      "Созданная заметка должна появиться в списке")
    }

    // MARK: - Поиск

    func testSearchFindsNote() throws {
        // Создаём заметку
        app.buttons[Constants.Accessibility.newNoteButton].tap()
        let titleField = app.textFields[Constants.Accessibility.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("УникальныйЗаголовок")
        app.buttons[Constants.Accessibility.backButton].tap()

        // Ищем
        let searchField = app.searchFields[Constants.Accessibility.searchField]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("уникальныйзаголовок")

        XCTAssertTrue(app.staticTexts["УникальныйЗаголовок"].waitForExistence(timeout: 5),
                      "Поиск должен найти заметку без учёта регистра")
    }

    func testSearchNothingFound() throws {
        let searchField = app.searchFields[Constants.Accessibility.searchField]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("zzz-несуществующий-запрос-zzz")

        XCTAssertTrue(app.staticTexts["Ничего не найдено"].waitForExistence(timeout: 5))
    }

    // MARK: - Открытие и удаление заметки

    func testOpenAndDeleteNote() throws {
        // Создаём
        app.buttons[Constants.Accessibility.newNoteButton].tap()
        let titleField = app.textFields[Constants.Accessibility.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("НаУдаление")
        app.buttons[Constants.Accessibility.backButton].tap()

        // Открываем
        let row = app.staticTexts["НаУдаление"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()

        // Удаляем через меню редактора
        let menuButton = app.buttons[Constants.Accessibility.editorMenu]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 10))
        menuButton.tap()
        app.buttons["Удалить"].tap()

        // Подтверждение удаления
        let confirm = app.buttons["Удалить"]
        if confirm.waitForExistence(timeout: 3) {
            confirm.tap()
        }

        let list = app.navigationBars["Заметки"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["НаУдаление"].exists, "Заметка должна быть удалена")
    }

    // MARK: - Настройки и тема

    func testOpenSettingsAndSwitchTheme() throws {
        app.buttons[Constants.Accessibility.settingsButton].tap()

        let settingsNav = app.navigationBars["Настройки"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 10), "Экран настроек должен открыться")

        let themePicker = app.buttons[Constants.Accessibility.themePicker]
        XCTAssertTrue(themePicker.waitForExistence(timeout: 5))
        themePicker.tap()
        app.buttons["Тёмная"].tap()

        // Возврат на главный экран
        settingsNav.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Заметки"].waitForExistence(timeout: 10))
    }
}
