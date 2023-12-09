//
//  LookAtThat-TracingTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/3/22.
//

@testable import LookAtThat_AppKit
import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import BitHandling
import SwiftGlyphs
import MetalLink
import MetalLinkHeaders
import MetalLinkResources
import Collections

import SwiftTreeSitter
import TreeSitterSwift


class LookAtThat_TracingTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        printStart()
        
        bundle = TestBundle()
        try bundle.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
        printEnd()
    }
    
    func testScalars() throws {
        let test = "🇵🇷"
        
        var counts: [Int: Int] = [:]
        for character in test {
            counts[character.unicodeScalars.count, default: 0] += 1
            if character.unicodeScalars.count > 6 {
                print(
                    character,
                    character.unicodeScalars
                        .map { "\($0.value)" }
                        .joined(separator: ", ")
                )
            }
        }
        print("Scalars in \(test.count) characters:")
        print(counts)
    }

    func testUnrenderedBlockSafetyAtlas() throws {
        let text = "𪘀" //TODO: This is just a sample unsupported glyph
        let text2 = "䗹" //TODO: This is just a sample unsupported glyph
        
        func makeData(_ text: String) throws -> Data {
            let builder = GlyphBuilder()
            let unrenderable = builder.makeBitmaps(
                GlyphCacheKey(source: text.first!, .white)
            )
            return try XCTUnwrap(unrenderable?.requested.tiffRepresentation)
        }
        let textData = try makeData(text)
        let textData2 = try makeData(text2)
        let allDataMatches =
               textData == textData2
            && textData2 == __UNRENDERABLE__GLYPH__DATA__
        XCTAssertTrue(allDataMatches, "The sample needs to fail correctly.")
    }
    
    func testAtlasLayout() throws {
        let atlas = GlobalInstances.defaultAtlas
        let compute = GlobalInstances.gridStore.sharedConvert
        let stopswatch = Stopwatch()

        let toRender = FileBrowser
            .recursivePaths(bundle.testDirectory)
            .lazy
            .filter { !$0.isDirectory }
            .prefix(1)
        
        var resultGrids = [CodeGrid]()
        stopswatch.start()
        let allComputedResults = try compute.executeManyWithAtlas(
            sources: Array(toRender),
            atlas: atlas
        )
        for result in allComputedResults {
            switch result.collection {
            case .built(let collection):
                let grid = CodeGrid(
                    rootNode: collection,
                    tokenCache: GlobalInstances.gridStore.globalTokenCache
                )
                let bounds = grid.sizeBounds
                print("Grid bounds: \(result.sourceURL.lastPathComponent) -> \(bounds)")
                resultGrids.append(grid)
                
            case .notBuilt:
                break
            }
        }
        let completionTime = stopswatch.elapsedTimeString()
        stopswatch.reset()
        
        print("Welp. They all.. stopped.")
        print("Completed in: \(completionTime)")
        print("Well then.")
    }
    
    func testRawDataLayout() throws {
        let atlas = GlobalInstances.defaultAtlas
        let compute = GlobalInstances.gridStore.sharedConvert
        let stopswatch = Stopwatch()
        
        var allBuffers = [(MTLBuffer, UInt32)]()
        var failedBuffers = [(MTLBuffer, UInt32)]()
        
//        let text = "X🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿2\n3🦾4🥰56"
//        let text = "X🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿2\n3🦾4🥰56X🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿2\n3🦾4🥰56"
//        for _ in (0..<10) {
//            doLayoutData(text.data!)
//        }

        func doLayoutData(_ data: Data, _ source: URL? = nil) {
            do {
                stopswatch.start()
                let (rawOutputBuffer, computedCharacterCount) = try compute.executeWithAtlasBuffer(
                    inputData: data,
                    atlasBuffer: atlas.currentBuffer
                )
                let (rawBufferPointer, rawBufferCount) = compute.cast(rawOutputBuffer)
                let finalizedBuffer = try compute.compressFreshMappedBuffer(unprocessedBuffer: rawOutputBuffer, expectedCount: computedCharacterCount)
                let finalizedPointer = finalizedBuffer.boundPointer(as: GlyphMapKernelOut.self, count: computedCharacterCount)
                allBuffers.append((rawOutputBuffer, computedCharacterCount))
                let message = source.map { $0.lastPathComponent } ?? String(data.count)
                print("Layed out: \(message): \(stopswatch.elapsedTimeString())")
                stopswatch.reset()
                
                let dataString = String(data: data, encoding: .utf8)
                let computeString = compute.makeGraphemeBasedString(from: rawBufferPointer, count: rawBufferCount)
                let makeNaiveConcatString = String(
                    (0..<computedCharacterCount)
                        .lazy
                        .map { finalizedPointer[Int($0)].expressedAsString }
                        .joined()
                )
                    
                let rawComputeStringsMatch = dataString == computeString
                let denoisedBufferMatches = dataString == makeNaiveConcatString
                
                let rawOffsets = (0..<rawBufferCount)
                    .map { rawBufferPointer[$0] }
                    .filter { $0.unicodeHash != 0 }
                    .map { "|| \($0.positionOffset.x), \($0.positionOffset.y) || [\($0.unicodeHash)] << raw " }
                
                let compressedOffsets = (0..<computedCharacterCount)
                    .map { finalizedPointer[Int($0)] }
                    .filter { $0.unicodeHash != 0 }
                    .map { "|| \($0.positionOffset.x), \($0.positionOffset.y) || [\($0.unicodeHash)] <.> cmprspsd" }
                /*
                (lldb) po (0..<rawBufferCount).map { rawBufferPointer[$0] }.filter { $0.unicodeHash != 0 }.map { "\($0.xOffset), \($0.yOffset)" }
                 */
                print("Raw offsets: (\(rawOffsets.count)) || Compressed offsets: (\(compressedOffsets.count))")
                XCTAssertTrue(rawComputeStringsMatch, "Gotta make the same fancy String as the Fancy String People")
                XCTAssertTrue(denoisedBufferMatches, "The cleanup buffer should end up with the same correct string as the raw buffer.")
                if !denoisedBufferMatches {
                    failedBuffers.append((finalizedBuffer, computedCharacterCount))
                }
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    private static let __ATLAS_SAVE_ENABLED__ = false
    func testAtlasSave() throws {
        XCTAssertTrue(Self.__ATLAS_SAVE_ENABLED__, "Not writing or checking for safety's safe; flip flag to actually save / write")
        guard Self.__ATLAS_SAVE_ENABLED__ else { return }
        
        var atlas = GlobalInstances.defaultAtlas
        
        // TODO: to 'reset' the atlas, load it up, the recreate it and save it
        GlobalInstances.recreateAtlas()
        atlas = GlobalInstances.defaultAtlas

        // --- Raw strings
//        let text = "0🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿23🦾4🥰56"
        let text = RAW_ATLAS_STRING_
        
        // --- Sample files
//        let testFile = bundle.testFile2
//        let text = try String(contentsOf: testFile)
        
        let test = text
        let testCount = test.count
        
        let compute = GlobalInstances.gridStore.sharedConvert
        let output = try compute.execute(inputData: test.data!)
        let (pointer, count) = compute.cast(output)
        
        var added = 0
        for index in (0..<count) {
            let pointee = pointer[index]
            let hash = pointee.unicodeHash
            guard hash > 0 else { continue; }
            
            // We should always get back 1 character.. that's.. kinda the whole point.
            let unicodeCharacter = pointee.expressedAsString.first!
            
            let key = GlyphCacheKey.fromCache(source: unicodeCharacter, .white)
            atlas.addGlyphToAtlasIfMissing(key)
            
            let _ = try XCTUnwrap(atlas.builder.cacheRef[key])
            added += 1
        }
        
        // TODO: Ya know, NOT FREAKING BAD for a first run!
        // I'm missing 20,000 characters. I'm sure a lot of those are non rendering and
        // I'm not filtering them out, but still, that's AWESOME so far!
//        XCTAssertEqual failed: ("435716") is not equal to ("457634") - Make all the glyphyees
        XCTAssertEqual(added, testCount, "Make all the glyphees")
        
        atlas.save()
//        atlas.load()
    }
    
    func testResaveAtlas() throws {
//        var atlas = GlobalInstances.defaultAtlas
//        atlas.save()
    }
    
    func testPrebuiltAtlas() throws {
        // TODO: loaded manually in app root, not really safe
        let atlas = GlobalInstances.defaultAtlas
        let atlasBuffer = try XCTUnwrap(atlas.currentBuffer, "Needs to have an existing (deserialized) buffer for this comparison to work.")
        let allFiles = bundle.testSourceDirectory!.enumeratedChildren().filter { !$0.isDirectory }
        
        let computeAtlas = GlobalInstances.gridStore.sharedConvert
        var allGlyphBuffers = [MTLBuffer]()
        for file in allFiles {
            let (parsedGlyphData, _) = try computeAtlas.executeWithAtlasBuffer(
                inputData: Data(contentsOf: file, options: .alwaysMapped),
                atlasBuffer: atlasBuffer
            )
            allGlyphBuffers.append(parsedGlyphData)
        }
        print("Made \(allGlyphBuffers.count)")
    }
    
    func testTreeSitter() throws {
        let language = Language(language: tree_sitter_swift())
        
        let parser = Parser()
        try parser.setLanguage(language)
        
        let path = URL(filePath: "/Users/ivanlugo/rapiddev/_personal/LookAtThat/Interop/Views/SourceInfoPanelState.swift")
        let testFile = try! String(contentsOf: path)
        let tree = parser.parse(testFile)!
        
        print(tree)
        
        let queryUrl = Bundle.main
                      .resourceURL?
                      .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
                      .appendingPathComponent("Contents/Resources/queries/highlights.scm")
        
        let query = try language.query(contentsOf: queryUrl!)
        let cursor = query.execute(node: tree.rootNode!, in: tree)
        
        for match in cursor {
            print("match: ", match.id, match.patternIndex)
            
            print("\t-- captures")
            for capture in match.captures {
                print("\t\t\(capture)")
                print("\t\t\(capture.nameComponents)")
                print("\t\t\(capture.metadata)")
            }
        }
    }
    
    class TreeSyntaxCollector {
        var rootNode: TreeSyntaxNode
        
        init(
            rootNode: TreeSyntaxNode
        ) {
            self.rootNode = rootNode
        }
    }
    
    class TreeSyntaxNode {
        var name: String
        var nameChildren: [String]
        var nameCaptures: [QueryCapture]
        init(
            name: String,
            nameChildren: [String],
            nameCaptures: [QueryCapture]
        ) {
            self.name = name
            self.nameChildren = nameChildren
            self.nameCaptures = nameCaptures
        }
    }
    
    func testDeepRecursion() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
        rootUrl.enumeratedChildren().forEach { print($0) }
    }
    
    func testClassCollection() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
        let dummyGrid = bundle.newGrid()
        let visitor = FlatteningVisitor(
            target: dummyGrid.semanticInfoMap,
            builder: dummyGrid.semanticInfoBuilder
        )
        
        try rootUrl.enumeratedChildren().forEach { url in
            guard !url.isDirectory else {
                return
            }
            let sourceFile = try XCTUnwrap(bundle.gridCache.loadSourceUrl(url), "Must render syntax from file")
            let sourceSyntax = Syntax(sourceFile)
            visitor.walkRecursiveFromSyntax(sourceSyntax)
        }
        
        let classes = dummyGrid.semanticInfoMap.classes.keys.compactMap {
            dummyGrid.semanticInfoMap.semanticsLookupBySyntaxId[$0]
        }.compactMap { (info: SemanticInfo) -> String? in
            "\(info.referenceName).self"
        }
        .sorted()
        .joined(separator: ",\n")
        
        
        print(classes)
        
        printEnd()
    }
    
    
}
