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
import SourceKittenFramework
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
    
    func testKitten() throws {
        printStart()
        
        SourceKittenConfiguration.preferInProcessSourceKit = false
        let swiftFilePath = bundle.testFileAbsolute
        print(swiftFilePath)
        
        let file = try XCTUnwrap(
            File(path: swiftFilePath),
            "Must create valid file path"
        )
        
        // String array of args, like in CLI:
        // $ > sourcekit -j4 /path/to/swiftfile.swift
        let docArguments = [
            "-j4", swiftFilePath
        ]
        
        let docs = try XCTUnwrap(
            SwiftDocs(file: file, arguments: docArguments),
            "Must load SwiftDocs from target file: \(file)"
        )
        
        print(docs)
        printEnd()
    }
}
