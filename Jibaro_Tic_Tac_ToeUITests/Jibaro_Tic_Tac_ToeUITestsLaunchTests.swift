//
//  Jibaro_Tic_Tac_ToeUITestsLaunchTests.swift
//  Jibaro_Tic_Tac_ToeUITests
//
//  Created by Juan C. Ribot on 11/2/25.
//

import XCTest

final class Jibaro_Tic_Tac_ToeUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
