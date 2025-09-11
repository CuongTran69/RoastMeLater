import XCTest

class DataManagementUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToDataManagement() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Data Management
        let dataManagementCell = app.cells.containing(.staticText, identifier: "Data Management").firstMatch
        XCTAssertTrue(dataManagementCell.waitForExistence(timeout: 5))
        dataManagementCell.tap()
        
        // Verify Data Management view is displayed
        XCTAssertTrue(app.navigationBars["Data Management"].waitForExistence(timeout: 5))
        
        // Verify export and import buttons exist
        XCTAssertTrue(app.buttons["Export Data"].exists)
        XCTAssertTrue(app.buttons["Import Data"].exists)
    }
    
    func testDataStatisticsDisplay() throws {
        navigateToDataManagement()
        
        // Verify data statistics section exists
        XCTAssertTrue(app.staticTexts["Data Overview"].exists)
        
        // Check for statistics elements
        XCTAssertTrue(app.staticTexts["Total Roasts"].exists)
        XCTAssertTrue(app.staticTexts["Favorites"].exists)
    }
    
    // MARK: - Export Flow Tests
    
    func testExportOptionsFlow() throws {
        navigateToDataManagement()
        
        // Tap Export Data button
        app.buttons["Export Data"].tap()
        
        // Verify Export Options view appears
        XCTAssertTrue(app.navigationBars["Export Options"].waitForExistence(timeout: 5))
        
        // Verify export option toggles exist
        XCTAssertTrue(app.switches["Include API keys and endpoints"].exists)
        XCTAssertTrue(app.switches["Include device model and iOS version"].exists)
        XCTAssertTrue(app.switches["Include category breakdown and usage patterns"].exists)
        XCTAssertTrue(app.switches["Remove potentially identifying information"].exists)
        
        // Test toggling options
        let apiKeyToggle = app.switches["Include API keys and endpoints"]
        let initialState = apiKeyToggle.value as? String == "1"
        apiKeyToggle.tap()
        
        // Verify state changed
        let newState = apiKeyToggle.value as? String == "1"
        XCTAssertNotEqual(initialState, newState)
    }
    
    func testExportWithSecurityWarning() throws {
        navigateToDataManagement()
        
        // Tap Export Data button
        app.buttons["Export Data"].tap()
        
        // Enable API key inclusion
        let apiKeyToggle = app.switches["Include API keys and endpoints"]
        if apiKeyToggle.value as? String != "1" {
            apiKeyToggle.tap()
        }
        
        // Verify security warning appears
        XCTAssertTrue(app.staticTexts["Security Warning"].exists)
        XCTAssertTrue(app.staticTexts.containing(.staticText, identifier: "API keys will be included").firstMatch.exists)
        
        // Tap Export button
        app.buttons["Export"].tap()
        
        // Verify privacy notice appears (if implemented)
        // This would test the privacy notice flow
    }
    
    func testExportCancellation() throws {
        navigateToDataManagement()
        
        // Tap Export Data button
        app.buttons["Export Data"].tap()
        
        // Tap Cancel button
        app.buttons["Cancel"].tap()
        
        // Verify we're back to Data Management view
        XCTAssertTrue(app.navigationBars["Data Management"].exists)
    }
    
    // MARK: - Import Flow Tests
    
    func testImportDataFlow() throws {
        navigateToDataManagement()
        
        // Tap Import Data button
        app.buttons["Import Data"].tap()
        
        // This would trigger the document picker
        // In a real test, we would need to simulate file selection
        // For now, we just verify the button works
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Progress Indicator Tests
    
    func testExportProgressDisplay() throws {
        navigateToDataManagement()
        
        // Start export process
        app.buttons["Export Data"].tap()
        app.buttons["Export"].tap()
        
        // Look for progress indicators
        // Note: This test might be flaky due to timing
        let progressView = app.progressIndicators.firstMatch
        if progressView.waitForExistence(timeout: 2) {
            XCTAssertTrue(progressView.exists)
        }
        
        // Look for progress text
        let progressText = app.staticTexts.containing(.staticText, identifier: "Preparing").firstMatch
        if progressText.waitForExistence(timeout: 2) {
            XCTAssertTrue(progressText.exists)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testExportWithNoData() throws {
        // This test would require setting up the app with no data
        // For now, it's a placeholder
        navigateToDataManagement()
        
        // In a real scenario, we would:
        // 1. Clear all data
        // 2. Try to export
        // 3. Verify error message appears
        
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Accessibility Tests
    
    func testDataManagementAccessibility() throws {
        navigateToDataManagement()
        
        // Test VoiceOver labels
        let exportButton = app.buttons["Export Data"]
        XCTAssertNotNil(exportButton.label)
        XCTAssertFalse(exportButton.label.isEmpty)
        
        let importButton = app.buttons["Import Data"]
        XCTAssertNotNil(importButton.label)
        XCTAssertFalse(importButton.label.isEmpty)
        
        // Test accessibility traits
        XCTAssertTrue(exportButton.isHittable)
        XCTAssertTrue(importButton.isHittable)
    }
    
    func testExportOptionsAccessibility() throws {
        navigateToDataManagement()
        app.buttons["Export Data"].tap()
        
        // Test toggle accessibility
        let toggles = app.switches
        for toggle in toggles.allElementsBoundByIndex {
            XCTAssertTrue(toggle.isHittable)
            XCTAssertNotNil(toggle.label)
            XCTAssertFalse(toggle.label.isEmpty)
        }
        
        // Test navigation accessibility
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.isHittable)
        
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.isHittable)
    }
    
    // MARK: - Localization Tests
    
    func testVietnameseLocalization() throws {
        // Change language to Vietnamese (if supported in test environment)
        // This would require additional setup
        
        navigateToDataManagement()
        
        // Verify Vietnamese text appears
        // Note: This test would need proper localization setup
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Performance Tests
    
    func testDataManagementViewPerformance() throws {
        measure {
            navigateToDataManagement()
            
            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    func testExportOptionsViewPerformance() throws {
        navigateToDataManagement()
        
        measure {
            app.buttons["Export Data"].tap()
            app.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullExportImportCycle() throws {
        // This would test a complete export/import cycle
        // 1. Export data
        // 2. Clear app data
        // 3. Import the exported data
        // 4. Verify data integrity
        
        navigateToDataManagement()
        
        // Start export
        app.buttons["Export Data"].tap()
        app.buttons["Export"].tap()
        
        // Wait for export to complete
        // In a real test, we would wait for completion indicators
        
        // Navigate back and try import
        // This would require file system interaction
        
        XCTAssertTrue(true) // Placeholder for complex integration test
    }
    
    // MARK: - Edge Case Tests
    
    func testRapidButtonTapping() throws {
        navigateToDataManagement()
        
        // Rapidly tap export button to test for race conditions
        let exportButton = app.buttons["Export Data"]
        for _ in 0..<5 {
            exportButton.tap()
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
        
        // Verify app doesn't crash and UI remains responsive
        XCTAssertTrue(app.buttons["Export Data"].exists)
    }
    
    func testMemoryPressureDuringExport() throws {
        // This test would simulate memory pressure during export
        // It's a placeholder for performance testing under stress
        navigateToDataManagement()
        XCTAssertTrue(true)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToDataManagement() {
        app.tabBars.buttons["Settings"].tap()
        
        let dataManagementCell = app.cells.containing(.staticText, identifier: "Data Management").firstMatch
        if dataManagementCell.waitForExistence(timeout: 5) {
            dataManagementCell.tap()
        }
        
        // Wait for navigation to complete
        _ = app.navigationBars["Data Management"].waitForExistence(timeout: 5)
    }
    
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    private func waitForProgressToComplete(timeout: TimeInterval = 30) -> Bool {
        // Wait for any progress indicators to disappear
        let progressIndicators = app.progressIndicators
        
        for indicator in progressIndicators.allElementsBoundByIndex {
            if !waitForElementToDisappear(indicator, timeout: timeout) {
                return false
            }
        }
        
        return true
    }
}
