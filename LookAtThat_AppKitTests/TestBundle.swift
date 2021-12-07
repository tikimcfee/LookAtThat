//
//  TestBundle.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import SwiftTrace
@testable import LookAtThat_AppKit

class TestBundle {
    
    static let testFileNames = [
        "WordNodeIntrospect",
        "RidiculousFile",
        "SmallFile"
    ]
    
    static let testFilesAbsolute = [
        URL(fileURLWithPath: "/Users/lugos/udev/manicmind/LookAtThat/Interop/DataVisualizers/CodeGrid/CodeGrid.swift")
    ]
    
    static let testDirectoriesAbsolute = [
        "/Users/lugos/udev/manicmind/LookAtThat",
        "/Users/lugos/udev/manicmind/otherfolks/swift-ast-explorer/.build/checkouts/swift-syntax/Sources/SwiftSyntax"
    ]
    
    static let testFileResourceURLs = testFileNames.compactMap {
        Bundle.main.url(forResource: $0, withExtension: "")
    }
    
    lazy var testFile = Self.testFileResourceURLs[0]
    lazy var testFileRaw = Self.testFilesAbsolute[0]
    var glyphs: GlyphLayerCache!
    var gridParser: CodeGridParser!
    var tokenCache: CodeGridTokenCache!
    var semanticBuilder: SemanticInfoBuilder!
    
    var testSourceDirectory: FileKitPath? {
        let absolutePath = Self.testDirectoriesAbsolute[0]
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: absolutePath, isDirectory: &isDirectory)
        guard exists, isDirectory.boolValue else {
            print("Could not resolve a directory for \(absolutePath)")
            return nil
        }
        
        return FileKitPath(absolutePath)
    }
    
    func setUpWithError() throws {
        gridParser = CodeGridParser()
        glyphs = gridParser.glyphCache
        tokenCache = gridParser.tokenCache
        semanticBuilder = SemanticInfoBuilder()
    }
    
    func tearDownWithError() throws {
        
    }
    
    func loadTestSource() throws -> SourceFileSyntax {
        try XCTUnwrap(
            gridParser.loadSourceUrl(testFile),
            "Failed to load test file"
        )
    }
}
