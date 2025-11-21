import XCTest
import StoreKitTest

final class ExpoStoreKitUITests: XCTestCase {
  private var session: SKTestSession!
  
  override func setUpWithError() throws {
    session = try SKTestSession(configurationFileNamed: "ExpoStoreKitConfiguration")
    session.clearTransactions()
  }
  
  override func tearDownWithError() throws {
    session = nil
  }
  
  @MainActor
  func testExample() throws {
    let app = XCUIApplication()
    app.launch()
    
    let runTestsButton = app.buttons["run-tests"]
    XCTAssertTrue(runTestsButton.waitForExistence(timeout: 20))
    runTestsButton.tap()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
      guard let self else { return }
      do {
        try self.session.forceRenewalOfSubscription(productIdentifier: "expo.storekit.subscription1")
      } catch {
        XCTFail("Failed to force subscription renewal: \(error)")
      }
    }
    
    let statusLabel = app.staticTexts["test-status"]
    XCTAssertEqual(statusLabel.wait(for: \.label, toEqual: "Status: success", timeout: 60), true)
  }
}
