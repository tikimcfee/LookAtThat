//
//  TestBundle.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SceneKit
import SwiftGlyph
@testable import SwiftGlyphsHI

class TestBundle {
    
    var rootDirectory: String
    lazy var testDirectory = URL(fileURLWithPath: rootDirectory).appending(path: "MetalLink/Sources/MetalLink/")
    lazy var testFile = testDirectory.appending(path: "MetalLink.swift")
    lazy var testFile2 = testDirectory.appending(path: "MetalLinkAliases.swift")
    
    init(
        root: String = ProcessInfo.processInfo.environment["test-path", default: "/Users/"]
    ) {
        self.rootDirectory = root
    }
    
    var testSourceDirectory: URL? {
        testDirectory
    }
    
    func setUpWithError() throws {

    }
    
    func tearDownWithError() throws {
        
    }
}

extension TestBundle {
    struct RawCode {
        static let A = "A"
        static let oneLine = "Hello, World!"
        static let twoLine = """
        Hello, yes.
        This is dog.
        """
        static let threeLine = """
        What if on the eve
        of the end of the world as
        it spun, it instead began?
        """
    }
}
