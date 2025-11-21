import XCTest
import StoreKitTest

final class ExpoStoreKitUITests: XCTestCase {
  override func setUpWithError() throws {
    let session = try SKTestSession(configurationFileNamed: "ExpoStoreKitConfiguration")
    session.clearTransactions()
  }
  
  @MainActor
  func testExample() throws {
    let app = XCUIApplication()
    app.launch()
    
    let runTestsButton = app.buttons["run-tests"]
    XCTAssertTrue(runTestsButton.waitForExistence(timeout: 20))
    runTestsButton.tap()
    
    let statusLabel = app.staticTexts["test-status"]
    XCTAssertEqual(statusLabel.wait(for: \.label, toEqual: "Status: success", timeout: 60), true)
  }
}
