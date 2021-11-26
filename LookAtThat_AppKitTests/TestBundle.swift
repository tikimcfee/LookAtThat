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
    
    static let testFileResourceURLs = testFileNames.compactMap {
        Bundle.main.url(forResource: $0, withExtension: "")
    }
    
    lazy var testFile = Self.testFileResourceURLs[0]
    var glyphs: GlyphLayerCache!
    var gridParser: CodeGridParser!
    var tokenCache: CodeGridTokenCache!
    var semanticBuilder: SemanticInfoBuilder!
    
    var wordNodeBuilder: WordNodeBuilder!
    
    var testSourceDirectory: FileKitPath? {
        let absolutePath = "/Users/lugos/udev/manicmind/LookAtThat/Interop"
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: absolutePath, isDirectory: &isDirectory)
        guard exists, isDirectory.boolValue else {
            print("Could not resolve a directory for \(absolutePath)")
            return nil
        }
        
        return FileKitPath(absolutePath)
    }
    
    func setUpWithError() throws {
        glyphs = GlyphLayerCache()
        gridParser = CodeGridParser()
        tokenCache = CodeGridTokenCache()
        semanticBuilder = SemanticInfoBuilder()
        
        wordNodeBuilder = WordNodeBuilder()
    }
    
    func tearDownWithError() throws {
        
    }
    
    func makeGrid() -> CodeGrid {
        CodeGrid(
            glyphCache: glyphs,
            tokenCache: tokenCache
        )
    }
    
    func loadTestSource() throws -> SourceFileSyntax {
        try XCTUnwrap(
            gridParser.loadSourceUrl(testFile),
            "Failed to load test file"
        )
    }
}
