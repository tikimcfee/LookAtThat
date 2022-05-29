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
    
    static let testTraceFile = URL(fileURLWithPath: "/Users/lugos/udev/manicmind/LookAtThat-FirstTrace/traces/app-trace-output-LugoWorkerPool-Serial-1.txt")
    
    static let coreGridDirectory = "/Users/lugos/udev/manicmind/LookAtThat/Interop/CodeGrids/CoreGrid/"
    
    static let testFilesRawPath = [
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/CodeGrids/CoreGrid/CodeGrid.swift",
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/CodeGrids/CoreGrid/CodeGrid+Measures.swift"
    ]
    static let testFilesAbsolute = [
        URL(fileURLWithPath: coreGridDirectory + "CodeGrid.swift")
    ]
    
    static let testDirectoriesAbsolute = [
        "/Users/lugos/udev/manicmind/LookAtThat",
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/",
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/CodeGrids/",
        "/Users/lugos/udev/manicmind/otherfolks/swift-ast-explorer/.build/checkouts/swift-syntax/Sources/SwiftSyntax"
    ]
    
    lazy var rootDirectory = "/Users/lugos/udev/manicmind/LookAtThat/"
    lazy var testFile = URL(fileURLWithPath: Self.testFilesRawPath[0])
    lazy var testFileRaw = Self.testFilesAbsolute[0]
    lazy var testFileAbsolute = Self.testFilesRawPath[0]
    lazy var testTraceFile = Self.testTraceFile
    var glyphs: GlyphLayerCache!
    var gridParser: CodeGridParser!
    var tokenCache: CodeGridTokenCache!
    var semanticBuilder: SemanticInfoBuilder!
    var controller: CodePagesController!
    
    var testSourceDirectory: URL? {
        let absolutePath = Self.testDirectoriesAbsolute[0]
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: absolutePath, isDirectory: &isDirectory)
        guard exists, isDirectory.boolValue else {
            print("Could not resolve a directory for \(absolutePath)")
            return nil
        }
        
        return URL(fileURLWithPath: absolutePath, isDirectory: true)
    }
    
    func setUpWithError() throws {
        gridParser = CodeGridParser()
        glyphs = gridParser.glyphCache
        tokenCache = gridParser.tokenCache
        semanticBuilder = SemanticInfoBuilder()
        controller = CodePagesController(sceneView: CustomSceneView(frame: .zero))
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
