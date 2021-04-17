//
//  GeoPicUITests.swift
//  GeoPicUITests
//
//  Created by John Choi on 2/17/21.
//

import XCTest

class GeoPicUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLogin() throws {
        // Logs in to user with email 123@123.com and password 1234567
        let app = XCUIApplication()
        app.launch()
        app.textFields["Email"].tap()
        app.buttons["Clear text"].tap()
        app.keys["more"].tap()
        app.keys["1"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
        app/*@START_MENU_TOKEN@*/.keys["@"]/*[[".keyboards.keys[\"@\"]",".keys[\"@\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.keys["1"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
        app.keyboards.children(matching: .other).element.children(matching: .other).element.children(matching: .key).matching(identifier: ".").element(boundBy: 1).tap()
        app.keys["more"].tap()
        app.keys["c"].tap()
        app.keys["o"].tap()
        app.keys["m"].tap()
        app.secureTextFields["Password"].tap()
        app.keys["more"].tap()
        app.keys["1"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
        app.keys["4"].tap()
        app.keys["5"].tap()
        app.keys["6"].tap()
        app.keys["7"].tap()
        app/*@START_MENU_TOKEN@*/.buttons["done"]/*[[".keyboards",".buttons[\"done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Login Successful"].scrollViews.otherElements.buttons["Yes"].tap()
        XCTAssertFalse(app.secureTextFields["Password"].exists)
    }

    //Must be run with app open and after successful login with pin clickable
    func testSelectingPin() throws {
        //Clicks pin then likes, then unlikes photo
        let app = XCUIApplication()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).matching(identifier: "Map pin").element(boundBy: 0).tap()
        app.buttons["(0)"].tap()
        app.buttons["(1)"].tap()
        XCTAssert(app.buttons["(0)"].exists)
    }
    
    //Must be run with app open on map view
    func testTakingPhoto() throws {
        //Opens camera, takes photo, then uploads
        let app = XCUIApplication()

        app.buttons["camera"].tap()
        app/*@START_MENU_TOKEN@*/.buttons["PhotoCapture"]/*[[".buttons[\"Take Picture\"]",".buttons[\"PhotoCapture\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(2)
        app.buttons["Use Photo"].tap()
        
        
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
