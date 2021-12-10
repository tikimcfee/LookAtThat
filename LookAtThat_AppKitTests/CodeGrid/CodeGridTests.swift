//
//  CodeGridTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import SwiftTrace
import Foundation
@testable import LookAtThat_AppKit

class LookAtThat_AppKitCodeGridTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
        
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
    }
    
    func testGridSizing() throws {
        bundle.gridParser.loadSourceUrl(bundle.testFile)?.tokens.forEach {
            print($0.triviaAndText)
            $0.triviaAndText.forEach {
                let (geometry, size) = bundle.glyphs[
                    GlyphCacheKey("\($0)", NSUIColor.white)
                ]
                
                print(size, "--", geometry.lengthX, geometry.lengthY, geometry.lengthZ)
                XCTAssertEqual(size.width, geometry.lengthX, accuracy: 0.0)
                XCTAssertEqual(size.height, geometry.lengthY, accuracy: 0.0)
            }
        }
    }
    
    func testSemanticInfo() throws {
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        //        grids.consume(syntax: sourceSyntax)
        
        for token in sourceSyntax.tokens {
            print(token.id.stringIdentifier, "\n\n---\n\(token.text) | \(token.typeName)\n---")
            var nextParent: Syntax? = token._syntaxNode
            while let next = nextParent?.parent {
                print("<--> \(next.id.stringIdentifier) | \(next.cachedType)")
                nextParent = next
            }
        }
    }
    
    func testRendering_versionTwo() throws {
        CodeGrid.Defaults.displayMode = .glyphs
        CodeGrid.Defaults.walkSemantics = false
        let rootDirectory = try XCTUnwrap(bundle.testSourceDirectory)
        measure {
            let awaitRender = expectation(description: "Version two rendered")
            bundle.gridParser.__versionTwo__RenderPathAsRoot(rootDirectory) { _ in
                print("receiver emitted for versionTwo")
                awaitRender.fulfill()
            }
            wait(for: [awaitRender], timeout: 60)
            bundle.glyphs = GlyphLayerCache()
            bundle.gridParser = CodeGridParser()
        }
    }
    
    
    func testRendering_versionThree() throws {
        CodeGrid.Defaults.displayMode = .glyphs
        CodeGrid.Defaults.walkSemantics = true
        let rootDirectory = try XCTUnwrap(bundle.testSourceDirectory)
        measure {
            let awaitRender = expectation(description: "Version three rendered")
            bundle.gridParser.__versionThree_RenderConcurrent(rootDirectory) { _ in
                print("receiver emitted versionThree")
                awaitRender.fulfill()
            }
            wait(for: [awaitRender], timeout: 60)
            bundle.glyphs = GlyphLayerCache()
            bundle.gridParser = CodeGridParser()
        }
    }
    
    func testSearch() throws {
        CodeGrid.Defaults.displayMode = .glyphs
        CodeGrid.Defaults.walkSemantics = true
        let rootDirectory = try XCTUnwrap(bundle.testSourceDirectory)
        let awaitRender = expectation(description: "Version three rendered")
        var finalNode: SCNNode?
        bundle.gridParser.__versionThree_RenderConcurrent(rootDirectory) { rootNode in
            print("Searchable grids rendered")
            finalNode = rootNode
            awaitRender.fulfill()
        }
        wait(for: [awaitRender], timeout: 60)
        let _ = try XCTUnwrap(finalNode, "wut missing root")
        
        var bimap: BiMap<CodeGrid, Int> = BiMap()
        var depth = 1
        bundle.gridParser.gridCache.cachedGrids.values.forEach { grid, clone in
            bimap[grid] = depth
            depth += 1
        }
        bimap.keysToValues.forEach { print($0) }
    }
    
    func testClones() throws {
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        
        let firstGrid = bundle.gridParser.createNewGrid()
            .consume(syntax: sourceSyntax)
            .sizeGridToContainerNode()
        var firstGridGlyphs = Set<SCNNode>()
        firstGrid.rootGlyphsNode.enumerateChildNodes { node, _ in
            firstGridGlyphs.insert(node)
        }
        
        let clonedGrid = firstGrid.makeClone()
        var clonedGridGlyphs = Set<SCNNode>()
        clonedGrid.rootGlyphsNode.enumerateChildNodes { node, _ in
            clonedGridGlyphs.insert(node)
        }
        
        XCTAssertEqual(firstGridGlyphs, clonedGridGlyphs)
    }
    
    func testAttributedWrites() throws {
        let testFile = bundle.testFile
        let fileData = try Data(contentsOfPath: FileKitPath(testFile.path))
        let dataString = try XCTUnwrap(String(data: fileData, encoding: .utf8))
        
        let dataStringAttributed = NSMutableAttributedString(
            string: dataString,
            attributes: [.foregroundColor: NSUIColor.red]
        )
        let appendedTestString = NSMutableAttributedString(
            string: "yet this is dog",
            attributes: [.foregroundColor: NSUIColor.blue]
        )
        dataStringAttributed.append(appendedTestString)
        
        let transformer = WireDataTransformer()
        let encodedTest = try XCTUnwrap(transformer.encodeAttributedString(dataStringAttributed))
        let (decodedTest, _) = try transformer.decodeAttributedString(encodedTest)
        print("Size of encode: \(encodedTest.mb)mb")
        XCTAssert(decodedTest == dataStringAttributed, "AttributedString write and re-read didn't reeturn same attributes")
    }
    
    func testRewriting() throws {
        let rewriter = TraceCapturingRewriter()
        let parsed = try! SyntaxParser.parse(bundle.testFileRaw)
        let rewritten = rewriter.visit(parsed)
        let rewrittenAgain = rewriter.visit(rewritten)
        XCTAssertEqual(rewritten, rewrittenAgain, "Should not modify already decorated contents")
        
        let fileRewriter = TraceFileWriter()
        fileRewriter.addTracesToFile(FileKitPath(bundle.testFileRaw.path))
    }
    
    func testTracing() throws {
        let parsed = try! SyntaxParser.parse(bundle.testFile)
        let testGridOne = CodeGrid(glyphCache: bundle.glyphs, tokenCache: bundle.tokenCache)
        testGridOne.consume(syntax: parsed.root).sizeGridToContainerNode()
        
        print(
            testGridOne.measures.leading,
            testGridOne.measures.top,
            testGridOne.measures.trailing,
            testGridOne.measures.bottom
        )
        
        XCTAssertEqual(testGridOne.measures.lengthX, testGridOne.backgroundGeometryNode.lengthX, "Size must be based off of background")
        XCTAssertEqual(testGridOne.measures.position, testGridOne.rootNode.position, "Position must be based off of rootNode")
        
        let testGridTwo = CodeGrid(glyphCache: bundle.glyphs, tokenCache: bundle.tokenCache)
        testGridTwo.consume(syntax: parsed.root).sizeGridToContainerNode()
        
        testGridOne.measures.alignedToBottomOf(testGridOne)
        XCTAssertGreaterThanOrEqual(testGridTwo.measures.top, testGridOne.measures.bottom, "Stacking is assumed to be a negative-y flow")
    }
    
    func testSnapping_EasyRight() throws {
        let snapping = WorldGridSnapping()
        
        let firstGrid = CodeGridEmpty.make()
        let second_toRightOfFirst = CodeGridEmpty.make()
        let third_toRightOfSecond = CodeGridEmpty.make()
        
        snapping.connect(sourceGrid: firstGrid, to: .right(second_toRightOfFirst))
        snapping.connect(sourceGrid: second_toRightOfFirst, to: .right(third_toRightOfSecond))
                
        let firstRelative = try XCTUnwrap(snapping.gridsRelativeTo(firstGrid).first,
                                          "Must find relative grid immediately")
        guard case WorldGridSnapping.RelativeGridMapping.right = firstRelative else {
            XCTFail("Where did \(firstRelative) come from?")
            return
        }
        
        let secondRelative = try XCTUnwrap(snapping.gridsRelativeTo(firstRelative.targetGrid).first,
                                           "Must find relative grid immediately")
        guard case WorldGridSnapping.RelativeGridMapping.right = secondRelative else {
            XCTFail("Where did \(secondRelative) come from???")
            return
        }
        
        XCTAssert(firstRelative.targetGrid === second_toRightOfFirst)
        XCTAssert(secondRelative.targetGrid === third_toRightOfSecond)
    }
    
    func testSnapping_Complicated() throws {
        let parsed = try SyntaxParser.parse(bundle.testFile)
        var allGrids = [CodeGrid]()
        func newGrid() -> CodeGrid {
            let newGrid = CodeGrid(glyphCache: bundle.glyphs,
                                   tokenCache: bundle.tokenCache)
                .consume(syntax: parsed.root)
                .sizeGridToContainerNode()
            
            allGrids.append(newGrid)
            return newGrid
        }
        
        let snapping = WorldGridSnapping()
        let firstGrid = newGrid()
        
        let gridCount = 10
        var focusedGrid = firstGrid
        
        (0..<gridCount).forEach { _ in
            let newGrid = newGrid()
            snapping.connectWithInverses(sourceGrid: focusedGrid, to: .forward(newGrid))
            focusedGrid = newGrid
        }
        focusedGrid = firstGrid
        
        let expectedRightCommands = gridCount
        let linkCount = expectation(description: "Traversal must occur exactly \(expectedRightCommands)")
        linkCount.expectedFulfillmentCount = expectedRightCommands
        var totalLengthX: VectorFloat = firstGrid.measures.lengthX
        snapping.iterateOver(focusedGrid, direction: .forward) { grid, stop in
            print(totalLengthX)
            totalLengthX += grid.measures.lengthX
            linkCount.fulfill()
        }
        wait(for: [linkCount], timeout: 1)
        let expectedLengthX = allGrids.reduce(into: VectorFloat(0)) { length, grid in
            length += grid.measures.lengthX
        }
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
        totalLengthX = firstGrid.measures.lengthX
        snapping.iterateOver(allGrids.last!, direction: .backward) { grid, stop in
            print(totalLengthX)
            totalLengthX += grid.measures.lengthX
        }
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
    }
    
    func testTries() throws {
        let referenceName = """
func someFunctionSignature(with aLongName: String) -> Wut { /* no-op */}S
"""
        XCTAssertTrue(referenceName.fuzzyMatch("func"))
        XCTAssertTrue(referenceName.fuzzyMatch("somesignature"))
        XCTAssertTrue(referenceName.fuzzyMatch("func string wut"))
        XCTAssertTrue(referenceName.fuzzyMatch("func wut"))
        XCTAssertFalse(referenceName.fuzzyMatch("func wut string"))
    }
    
}
