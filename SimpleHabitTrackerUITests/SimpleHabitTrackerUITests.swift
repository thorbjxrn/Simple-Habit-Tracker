import XCTest

final class SimpleHabitTrackerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 1. testAddHabit

    func testAddHabit() throws {
        dismissOnboardingIfNeeded()

        // Tap the + button in the navigation bar
        let addButton = app.navigationBars.buttons.element(boundBy: 1) // trailing button
        if !addButton.waitForExistence(timeout: 3) {
            XCTFail("Could not find the add habit button")
            return
        }
        addButton.tap()

        // Wait for the alert to appear
        let alert = app.alerts["Add New Habit"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Add New Habit alert should appear")

        // Type a habit name into the text field
        let textField = alert.textFields.firstMatch
        XCTAssertTrue(textField.exists, "Text field should exist in the alert")
        textField.tap()
        textField.typeText("Test Habit")

        // Tap the Add button in the alert
        alert.buttons["Add"].tap()

        // Verify the habit appears in the list
        let habitText = app.staticTexts["Test Habit"]
        XCTAssertTrue(habitText.waitForExistence(timeout: 3), "Newly added habit should appear in the list")
    }

    // MARK: - 2. testSettingsNavigation

    func testSettingsNavigation() throws {
        dismissOnboardingIfNeeded()

        // Tap the gear/settings button (leading button in the navigation bar)
        let settingsButton = app.navigationBars.buttons.element(boundBy: 0) // leading button
        if !settingsButton.waitForExistence(timeout: 3) {
            XCTFail("Could not find the settings button")
            return
        }
        settingsButton.tap()

        // Verify Settings screen appears by checking for the navigation title
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3), "Settings screen should appear")

        // Verify some expected settings content is visible
        let premiumSection = app.staticTexts["Premium"]
        XCTAssertTrue(premiumSection.waitForExistence(timeout: 2), "Premium section should be visible in Settings")
    }

    // MARK: - Helpers

    private func dismissOnboardingIfNeeded() {
        // Onboarding is a full-screen cover with a "Get Started" button on page 2.
        // Check if the onboarding welcome text is visible.
        let welcomeText = app.staticTexts["Track your habits,"]
        guard welcomeText.waitForExistence(timeout: 2) else {
            // No onboarding - already dismissed or completed
            return
        }

        // Swipe left to go to page 2 (tutorial page)
        app.swipeLeft()

        // Now tap "Get Started" which becomes visible on page 2
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 3) {
            getStarted.tap()
        }

        // Wait for the main navigation bar to appear
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
    }
}
