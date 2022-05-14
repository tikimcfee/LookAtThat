//
//  CodePagesTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/10/22.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import Foundation
@testable import LookAtThat_AppKit

class LookAtThat_AppKit_CodePagesTests: XCTestCase {
    var bundle: TestBundle!

    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()

    }

    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
    }
    
    func testLSP() throws {
        printStart()

        let lsp = CodePagesGridLSP()
        let expected = expectation(description: "Got response from LSP")
        lsp.start {
            expected.fulfill()
        }
        wait(for: [expected], timeout: 5)
        
        printEnd()
    }
}
