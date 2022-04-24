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
@testable import LookAtThat_AppKit

class TestBundle {
    
    static let rewriteDirectories = [
        "/Users/lugos/udev/manicmind/LookAtThat"
    ]
    
    static let testFileNames = [
        "WordNodeIntrospect",
        "RidiculousFile",
        "SmallFile"
    ]
    
    static let coreGridDirectory = "/Users/lugos/udev/manicmind/LookAtThat/Interop/DataVisualizers/CodeGrids/CoreGrid/"
    static let testFilesAbsolute = [
        URL(fileURLWithPath: coreGridDirectory + "CodeGrid.swift")
    ]
    
    static let testDirectoriesAbsolute = [
        "/Users/lugos/udev/manicmind/LookAtThat",
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/DataVisualizers/CodeGrids/",
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
        let absolutePath = Self.testDirectoriesAbsolute[1]
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
            gridParser.loadSourceUrl(testFileRaw),
            "Failed to load test file"
        )
    }
}
