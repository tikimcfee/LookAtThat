//
//  GlyphTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 6/10/22.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import Foundation
@testable import LookAtThat_AppKit

class LookAtThat_AppKit_GlyphTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        printStart()
        
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
        
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
        
        printEnd()
    }
    
    func testGlyphKeyFileURLs() throws {
        let testChar = "🥸"
        let testForeground = NSUIColor(displayP3Red: 0.0, green: 0.1312, blue: 0.331, alpha: 1.0)
        let testBackground = NSUIColor(displayP3Red: 0.2, green: 0.3, blue: 0.4, alpha: 0.5)
        print("char: ", testChar)
        print("fore: ", testForeground)
        print("back: ", testBackground)
        
        let testUtf8 = try XCTUnwrap(testChar.data(using: .utf8), "Must encode test glyph")
        let hex = testUtf8.hexString
        print("hex:  ", hex)
        
        let dataToString = try XCTUnwrap(hex.convertedFromHexToText, "Must decode string")
        print("text: ", dataToString)
        XCTAssertEqual(testChar, dataToString, "Round trip must succeed")
        
        let testKey = GlyphCacheKey(testChar, testForeground, testBackground)
        
        let persistKey = try XCTUnwrap(testKey.asPersistedName, "Must create valid persist name")
        print("persit key:  ", persistKey)
        
        let fileComponent = try XCTUnwrap(persistKey.fileNameComponent, "Must create file name from key")
        print("persit name: ", fileComponent)
        
        let fileGlyph = try XCTUnwrap(persistKey.asCacheKey, "Must create valid cache key")
        print(fileGlyph)
        print(testKey)
        XCTAssertEqual(testKey, fileGlyph, "Keys must match for dictionary to work")
        print("----------")
        
        let nameComponent = persistKey.fileNameComponent
        let testkeyUrl = AppFiles.rawGlyph(named: nameComponent)
        print(nameComponent, "->", testkeyUrl)
        let urlName = testkeyUrl.lastPathComponent
        print(urlName)
        XCTAssertEqual(nameComponent, urlName, "Name must round trip from file path")
        
        let fullRoundTripKey = try XCTUnwrap(GlyphCacheKey.Name(urlName), "Must create key from roundtrip name")
        let finalRoundTripGlyphKey = try XCTUnwrap(fullRoundTripKey.asCacheKey, "Must create final glyph key from round trip")
        print("----------")
        print(finalRoundTripGlyphKey)
        XCTAssertEqual(testKey, finalRoundTripGlyphKey, "Final key must match initial")
    }
    
    func testGlyphKeyReify() throws {
        let testChar = "🥸"
        let testForeground = NSUIColor(displayP3Red: 0.0, green: 0.1312, blue: 0.331, alpha: 1.0)
        let testBackground = NSUIColor(displayP3Red: 0.2, green: 0.3, blue: 0.4, alpha: 0.5)
        let startKey = GlyphCacheKey(testChar, testForeground, testBackground)
        let fileUrl = try XCTUnwrap(startKey.asPersistedUrl, "Must produce valid file url")
        let reifiedKey = try XCTUnwrap(GlyphCacheKey.reify(from: fileUrl.lastPathComponent), "Must reify from file name")
        print(startKey)
        print(reifiedKey)
        XCTAssertEqual(reifiedKey, startKey, "Reified key must match start key")
    }
    
    func testGlyphIO() throws {
        
    }
}
