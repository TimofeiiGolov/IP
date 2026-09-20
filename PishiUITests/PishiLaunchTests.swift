// File: PishiUITests/PishiLaunchTests.swift
import XCTest

final class PishiLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testLaunchShowsMainScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Заметки"].waitForExistence(timeout: 15))
    }
}
