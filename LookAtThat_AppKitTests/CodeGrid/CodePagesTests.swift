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
    
    func testPathEncoding() throws {
        printStart()
        
        let pathSource = URL(bundle.testFileAbsolute)
        print(pathSource)
        let pathJson = try JSONEncoder().encode(pathSource)
        print("encoded", pathJson.count)
        let pathStringRep = try XCTUnwrap(String(data: pathJson, encoding: .utf8), "json must be decodable as utf8")
        print(pathStringRep)
        
        let scopeSource = FileBrowser.Scope.file(pathSource)
        print("scope source:\n", scopeSource)
        let scopeJson = try JSONEncoder().encode(scopeSource)
        print("encoded", scopeJson.count)
        let scopeStringRep = try XCTUnwrap(String(data: scopeJson, encoding: .utf8), "json must be decodable as utf8")
        print(scopeStringRep)
        
        let reified = try JSONDecoder().decode(FileBrowser.Scope.self, from: scopeJson)
        print("scope reified:\n", reified)
        XCTAssertEqual(reified, scopeSource, "Round trip encoding must succeed")
        
        printEnd()
    }
}
