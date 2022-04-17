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
        bundle.gridParser.__versionThree_RenderConcurrent(rootDirectory) { rootGrid in
            print("Searchable grids rendered")
            finalNode = rootGrid.rootNode
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
        firstGrid.rawGlyphsNode.enumerateChildNodes { node, _ in
            firstGridGlyphs.insert(node)
        }
        
        let clonedGrid = firstGrid.makeClone()
        var clonedGridGlyphs = Set<SCNNode>()
        
        clonedGrid.rawGlyphsNode.enumerateChildNodes { node, _ in
            clonedGridGlyphs.insert(node)
        }
        
        let firstNames = firstGridGlyphs.reduce(into: Set<String>()) { $0.insert($1.name) }
        let secondNames = clonedGridGlyphs.reduce(into: Set<String>()) { $0.insert($1.name) }
        
        XCTAssertEqual(firstNames, secondNames)
    }
    
    func testFileBrowser() throws {
        let testFile = bundle.testFile
        let testPathStart = try XCTUnwrap(FileKitPath(url: testFile), "Need a working url to test")
        let testPathParent = try XCTUnwrap(testPathStart.parent.parent.parent, "Need a working url to test")
        
        let scopeStart = FileBrowser.Scope.file(testPathStart)
        let scopeParent = FileBrowser.Scope.file(testPathParent)
        
        let browser = FileBrowser()
        browser.scopes.append(scopeParent)
        
        let depth = browser.distanceToRoot(scopeStart)
        
        print("Depth: \(depth)")
        XCTAssertEqual(depth, 3, "Calls to parent and depth count must match")
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
        XCTAssertEqual(rewritten.description, rewrittenAgain.description, "Rewrites should always result in the save end string")
        
        let fileRewriter = TraceFileWriter()
        fileRewriter.addTracesToFile(FileKitPath(bundle.testFileRaw.path))
    }
    
    func test__RewritingAll() throws {
        let fileRewriter = TraceFileWriter()
        
        printStart()
        let root = TestBundle.rewriteDirectories.first!
        let finder = TracingFileFinder()
        
        finder.findFiles(root).forEach { path in
            fileRewriter.addTracesToFile(path)
        }
        
        printEnd()
    }
    
    func testSnapping_EasyRight() throws {
        let snapping = WorldGridSnapping()
        
        class CodeGridEmpty: CodeGrid {
            static let emptyGlyphCache = GlyphLayerCache()
            static let emptyTokenCache = CodeGridTokenCache()
            static func make() -> CodeGrid {
                laztrace(#fileID,#function)
                return CodeGrid(
                    glyphCache: emptyGlyphCache,
                    tokenCache: emptyTokenCache
                )
            }
        }
        
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
    
    func stats(_ testGrid: CodeGrid) {
        let testGridWidth = testGrid.measures.lengthX
        let testGridHeight = testGrid.measures.lengthY
        let testGridLength = testGrid.measures.lengthZ
        let testGridCenter = testGrid.measures.centerPosition
        print()
        print(testGrid.fileName)
        print("gw:\(testGridWidth), gh:\(testGridHeight), gl:\(testGridLength), gcenter: \(testGridCenter)")
        
        let manualWidth = BoundsWidth(testGrid.rootNode.manualBoundingBox)
        let manualHeight = BoundsHeight(testGrid.rootNode.manualBoundingBox)
        let manualLength = BoundsLength(testGrid.rootNode.manualBoundingBox)
        let manualCenter = testGrid.rootNode.boundsCenterPosition
        let manualCenterConverted = testGrid.rootNode.convertPosition(manualCenter, to: testGrid.rootNode.parent)
        print("mw:\(manualWidth), mh:\(manualHeight), ml:\(manualLength), mcenter: \(manualCenter), mcenterConv: \(manualCenterConverted)")
        print()
    }
    
    func testPositions() throws {
        let parsed = try SyntaxParser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            CodeGrid(glyphCache: bundle.glyphs,
                     tokenCache: bundle.tokenCache)
                .withFileName(bundle.testFile.lastPathComponent)
                .consume(syntax: parsed.root)
                .sizeGridToContainerNode()
        }
        let testGrid = newGrid()
        var (deltaX, deltaY, deltaZ) = (0.0, 0.0, 0.0)
        
        printStart()
        print("start: ----")
        print(testGrid.measures.dumpstats)

        XCTAssertEqual(testGrid.measures.position, SCNVector3Zero, "Must start at 0,0,0")
        
        testGrid.measures.setLeading(0)
        testGrid.measures.setTop(0)
        testGrid.measures.setBack(0)
        print("after translate: ----")
        print(testGrid.measures.dumpstats)
        
        deltaX = abs(testGrid.measures.leadingOffset - testGrid.measures.xpos)
        deltaY = abs(testGrid.measures.topOffset + testGrid.measures.ypos)
        deltaZ = abs(testGrid.measures.backOffset - testGrid.measures.zpos)
        XCTAssertLessThanOrEqual(abs(deltaX), 0.001, "Float difference must be very small")
        XCTAssertLessThanOrEqual(abs(deltaY), 0.001, "Float difference must be very small")
        XCTAssertLessThanOrEqual(abs(deltaZ), 0.001, "Float difference must be very small")

        let alignedGrid = newGrid()
        print("new grid: ----")
        print(alignedGrid.measures.dumpstats)
        alignedGrid.measures.setLeading(testGrid.measures.trailing)
        
        print("after align: ----")
        print(alignedGrid.measures.dumpstats)
    
        printEnd()
    }
    
    func testMeasuresAndSizes() throws {
        let parsed = try SyntaxParser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            CodeGrid(glyphCache: bundle.glyphs,
                     tokenCache: bundle.tokenCache)
                .consume(syntax: parsed.root)
                .sizeGridToContainerNode()
        }
        
        let testGrid = newGrid()
        stats(testGrid)
        XCTAssert(testGrid.measures.lengthX > 0, "Should have some size")
        XCTAssertEqual(testGrid.rootNode.position, SCNVector3Zero, "Must start at zero position for test")
        
        // Test initial sizing works
        let testGridWidth = testGrid.measures.lengthX
        let testGridHeight = testGrid.measures.lengthY
        let testGridLength = testGrid.measures.lengthZ
        
        let centerPosition = testGrid.measures.centerPosition
        var centerX = centerPosition.x
        var centerY = centerPosition.y
        var centerZ = centerPosition.z
        
        let expectedCenterX = testGrid.measures.leading + testGridWidth / 2.0
        let expectedCenterY = testGrid.measures.top - testGridHeight / 2.0
        let expectedCenterZ = testGrid.measures.front - testGridLength / 2.0
        
        XCTAssertGreaterThanOrEqual(expectedCenterX, 0, "Grids at (0,0,0) expected to draw left to right; its center should ahead of that point")
        XCTAssertLessThanOrEqual(expectedCenterY, 0, "Grids at (0,0,0) expected to draw top to bottom; its center should be below that point")
//        XCTAssertGreaterThanOrEqual(expectedCenterZ, 0, "Grids at (0,0,0) expected to draw front to back; its center should behind that point")
        
        let deltaX = abs(centerX - expectedCenterX)
        let deltaY = abs(centerY - expectedCenterY)
        let deltaZ = abs(centerZ - expectedCenterZ)
        XCTAssertLessThanOrEqual(deltaX, 0.001, "Error must be in range")
        XCTAssertLessThanOrEqual(deltaY, 0.001, "Error must be in range")
        XCTAssertLessThanOrEqual(deltaZ, 0.001, "Error must be in range")
        
        /// NOTE: This is linearly increasing to test a cached bounds issue,
        /// and to more easily detect patterns with problem result positions
        doTranslateTest(-5)
        doTranslateTest(-5)
        doTranslateTest(-4)
        doTranslateTest(-3)
        doTranslateTest(-2)
        doTranslateTest(-1)
        doTranslateTest(0)
        doTranslateTest(1)
        doTranslateTest(2)
        doTranslateTest(3)
        doTranslateTest(4)
        doTranslateTest(5)
        doTranslateTest(6)
        doTranslateTest(1000)
        doTranslateTest(-10000)
        doTranslateTest(194.231)
        
        // Move node, then test the expected position comes back
        func doTranslateTest(_ delta: VectorFloat) {
            testGrid.translated(dX: delta, dY: delta, dZ: delta)
            
            stats(testGrid)
            
            let newCenterPosition = testGrid.measures.centerPosition
            let newCenterX = newCenterPosition.x
            let newCenterY = newCenterPosition.y
            let newCenterZ = newCenterPosition.z
            
            let newExpectedCenterX = centerX + delta
            let newExpectedCenterY = centerY + delta
            let newExpectedCenterZ = centerZ + delta
            
            // TODO: -- Rounding between boxes and positions is off
            // Current measurements and position have a precision of about 3-4 places.
            let deltaX = abs(newCenterX - newExpectedCenterX)
            let deltaY = abs(newCenterY - newExpectedCenterY)
            let deltaZ = abs(newCenterZ - newExpectedCenterZ)
            XCTAssertLessThanOrEqual(deltaX, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(deltaY, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(deltaZ, 0.1, "Error should be within 1 point")
            
            centerX = newExpectedCenterX
            centerY = newExpectedCenterY
            centerZ = newExpectedCenterZ
            
            let newBounds = testGrid.rootNode.manualBoundingBox
            let newBoundsWidth = BoundsWidth(newBounds) * DeviceScale
            let newBoundsHeight = BoundsHeight(newBounds) * DeviceScale
            let newBoundsLength = BoundsLength(newBounds) * DeviceScale
            let newBoundsCenter = testGrid.rootNode.boundsCenterPosition
            
            let sizeDeltaX = abs(testGridWidth - newBoundsWidth)
            let sizeDeltaY = abs(testGridHeight - newBoundsHeight)
            let sizeDeltaZ = abs(testGridLength - newBoundsLength)
            
            XCTAssertLessThanOrEqual(sizeDeltaX, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(sizeDeltaY, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(sizeDeltaZ, 0.1, "Error should be within 1 point")
            
            let boundsDeltaX = abs(newCenterX - newBoundsCenter.x)
            let boundsDeltaY = abs(newCenterY - newBoundsCenter.y)
            let boundsDeltaZ = abs(newCenterZ - newBoundsCenter.z)
            
            XCTAssertLessThanOrEqual(boundsDeltaX, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(boundsDeltaY, 0.1, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(boundsDeltaZ, 0.1, "Error should be within 1 point")
        }
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
        func sumLength(grid: CodeGrid, _ direction: SelfRelativeDirection, _ op: @escaping () -> Void ) {
            snapping.iterateOver(grid, direction: direction) { _, grid, stop in
                print(grid.id, totalLengthX)
                totalLengthX += grid.measures.lengthX
                op()
            }
        }
        printStart()
        sumLength(grid: focusedGrid, .forward) { linkCount.fulfill() }
        wait(for: [linkCount], timeout: 1)
        printEnd()
        
        let expectedLengthX = allGrids.reduce(into: VectorFloat(0)) { length, grid in
            length += grid.measures.lengthX
        }
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
        
        totalLengthX = firstGrid.measures.lengthX
        printStart()
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
        printEnd()
        
        let oneGridLength = firstGrid.measures.lengthX
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[2])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength, "Retaining detach should do the retaining thing")
        printEnd()
        
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[7])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength - oneGridLength, "Retaining detach should do the retaining thing")
        printEnd()
        
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[4])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength - oneGridLength - oneGridLength, "Retaining detach should do the retaining thing")
        printEnd()
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
