//
//  CodeGridTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import BitHandling
import MetalLinkHeaders
import MetalLinkResources
import MetalLink
@testable import LookAtThat_AppKit

extension Parser {
    static func parse(_ url: URL) throws -> SourceFileSyntax {
        let source = try String(contentsOf: url)
        return Parser.parse(source: source)
    }
}

class LookAtThat_AppKitCodeGridTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
        printStart()
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
        printEnd()
    }
    
    func testDirectoriesFirst() throws {
        let root = try XCTUnwrap(URL(string: "file:///Users/lugos/udev/manicmind/LookAtThat/"), "Must have valid root")
                
        root.enumeratedChildren()
            .filter { $0.isDirectory }
            .forEach {
                print($0)
            }
    }
   
    func testPathParentCounting() throws {
        let root = URL(string: "file:///Users/lugos/udev/manicmind/LookAtThat/")!
        
        let allDirectories = FileBrowser
            .recursivePaths(root)
            .filter { $0.isDirectory }
        
        let parentCount = allDirectories.reduce(into: [URL: Int]()) { result, url in
            result[url] = FileBrowser.distanceTo(parent: .directory(root), from: .directory(url))
        }
        
        parentCount
            .sorted(by: {
                $0.key.pathComponents.count < $1.key.pathComponents.count
            })
            .forEach { key, value in
                print(key, value)
            }
    }
    
    func testSemanticInfo() throws {
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        
        for token in sourceSyntax.tokens(viewMode: .all) {
            print(token.id.stringIdentifier, "\n\n---\n\(token.text)\n---")
            var nextParent: Syntax? = token._syntaxNode
            while let next = nextParent?.parent {
                print("<--> \(next.id.stringIdentifier)")
                nextParent = next
            }
        }
    }
    
    func testFileRecursion() throws {
        let path = try XCTUnwrap(URL(string: bundle.rootDirectory), "Must have valid root directory")
        FileBrowser.recursivePaths(path).forEach {
            print("\($0.description)")
        }
    }
    
    func testLinkParenting() throws {
        let link = GlobalInstances.defaultLink
        let builder = try CodeGridGlyphCollectionBuilder(
            link: link,
            sharedSemanticMap: SemanticInfoMap(),
            sharedTokenCache: CodeGridTokenCache(),
            sharedGridCache: bundle.gridCache
        )
        builder.mode = .multiCollection
        
        func consumed(_ url: URL) -> GlyphCollectionSyntaxConsumer {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: url)
            return consumer
        }
        
        let testGrid1 = consumed(bundle.testFile).targetGrid
        print(testGrid1.position)
        
        let root = RootNode(DebugCamera(link: link))
        root.add(child: testGrid1.targetNode)
        print(testGrid1.position)
        
        root.position.x += 10
        root.position.z -= 30
        print("parent: ", root.position)
        print("grid:   ", testGrid1.position)
        print("gridW:  ", testGrid1.worldPosition)
        print("bg:     ", testGrid1.gridBackground.position)
        print("bgW:    ", testGrid1.gridBackground.worldPosition)
        print("bgB:    ", testGrid1.gridBackground.bounds)
        print("bgWB:   ", testGrid1.gridBackground.worldBounds)
    }
    
    func testLinkNodeSetters() throws {
        let link = GlobalInstances.defaultLink
        let builder = try CodeGridGlyphCollectionBuilder(
            link: link,
            sharedSemanticMap: SemanticInfoMap(),
            sharedTokenCache: CodeGridTokenCache(),
            sharedGridCache: bundle.gridCache
        )
        builder.mode = .multiCollection
        
        func consumed(_ url: URL) -> GlyphCollectionSyntaxConsumer {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: url)
            return consumer
        }
        
        let testGrid1 = consumed(bundle.testFile).targetGrid
        let testGrid2 = consumed(bundle.testFile).targetGrid
        
        testGrid2.position = LFloat3(123_456, 654_321, 987_654)
        
        // call multiple times to make sure it isn't additive.
        testGrid2.setLeading(testGrid1.localLeading)
        testGrid2.setLeading(testGrid1.localLeading)
        testGrid2.setLeading(testGrid1.localLeading)
        XCTAssertEqual(testGrid2.localLeading, testGrid1.localLeading, "There should be no offset after setting")
        
        testGrid2.setLeading(testGrid1.localTrailing)
        XCTAssertEqual(testGrid2.localLeading, testGrid1.localTrailing, "There should be no offset after setting")
        
        testGrid2.setTrailing(testGrid1.localTrailing)
        XCTAssertEqual(testGrid2.localTrailing, testGrid1.localTrailing, "There should be no offset after setting")
        
        testGrid2.setTop(testGrid1.localTop)
        XCTAssertEqual(testGrid2.localTop, testGrid1.localTop, "There should be no offset after setting")
        
        testGrid2.setBottom(testGrid1.localBottom)
        XCTAssertEqual(testGrid2.localBottom, testGrid1.localBottom, "There should be no offset after setting")
        
        testGrid2.setFront(testGrid1.localFront)
        XCTAssertEqual(testGrid2.localFront, testGrid1.localFront, "There should be no offset after setting")
        
        testGrid2.setBack(testGrid1.localBack)
        XCTAssertEqual(testGrid2.localBack, testGrid1.localBack, "There should be no offset after setting")
    }
    
    func testLinkNodeStatsForMultiCollection() throws {
        let link = GlobalInstances.defaultLink
        let builder = try CodeGridGlyphCollectionBuilder(
            link: link,
            sharedSemanticMap: SemanticInfoMap(),
            sharedTokenCache: CodeGridTokenCache(),
            sharedGridCache: bundle.gridCache
        )
        let consumer = builder.createConsumerForNewGrid()
        consumer.consume(url: bundle.testFile)
        let testGrid = consumer.targetGrid
            .withFileName(bundle.testFile.lastPathComponent)
        
        XCTAssertFalse(
            testGrid.tokenCache.isEmpty(),
            "TokenCache must have built nodes"
        )
        
        func performChecks() {
            let testBounds = BoxComputing()
            testGrid.tokenCache.doOnEach { id, nodeSet in
                for node in nodeSet {
                    XCTAssertTrue(node.contentSize.x > 0, "Glyph nodes usually have some width")
                    XCTAssertTrue(node.contentSize.y > 0, "Glyph nodes usually have some height")
                    XCTAssertTrue(node.contentSize.z > 0, "Glyph nodes usually have some depth")
                    
                    // TODO: WARNING! CAREFUL! OH NO! `.bounds` is still rocky!
                    // node.bounds gave local bounds. Without calling convert directly,
                    // the glyphs aren't properly positioned. This is a weird test,
                    // as it's checking that nodes and grids align after blitting,
                    // but it's caught a bunch of stuff so far so I'm keeping it.
                    // For now, this behavior is mostly OK, but be warned when
                    // when interacting the glyph node positioning directly.
                    testBounds.consumeBounds(node.computeBoundingBox())
                }
            }
            // NOTE: This test will fail if whitespaces/newlines aren't added to constants.
            // The above bounds are computed with all nodes.
            print("computed grid size: ", BoundsSize(testGrid.bounds))
            print("computed test size: ", BoundsSize(testBounds.bounds))
            
            print("grid world bounds: ", testGrid.bounds)
            print("test world bounds: ", testBounds.bounds)
            XCTAssertEqual(
                testBounds.bounds.min,
                testGrid.bounds.min,
                "Bounds min must match from node calculation and grid measures"
            )
            
            XCTAssertEqual(
                testBounds.bounds.max,
                testGrid.bounds.max,
                "Bounds max must match from node calculation and grid measures"
            )
        }
        
        performChecks()
        testGrid.translated(dX: 10, dY: 0, dZ: 0)
        performChecks()
        testGrid.translated(dX: 0, dY: 10, dZ: 0)
        performChecks()
        testGrid.translated(dX: 0, dY: -20, dZ: 0)
        performChecks()
        testGrid.translated(dX: 0, dY: 0, dZ: -10)
        performChecks()
        testGrid.translated(dX: 0, dY: 0, dZ: 20)
        performChecks()
        testGrid.zeroedPosition()
        performChecks()
    }
    
    func testGridSize() throws {
        printStart()
        
        let parsed = try Parser.parse(bundle.testFile)
        let testGrid = bundle.newGrid()
            .withFileName(bundle.testFile.lastPathComponent)
            .consume(rootSyntaxNode: parsed.root)
        
        //        let testClass = try XCTUnwrap(
        //            testGrid.semanticInfoMap.classes.first,
        //            "Must have id to test"
        //        )
        
        let (x, y, z) = (
            testGrid.lengthX,
            testGrid.lengthY,
            testGrid.lengthZ
        )
        
        XCTAssertGreaterThan(x, 0, "Must have some width")
        XCTAssertGreaterThan(y, 0, "Must have some height")
        XCTAssertGreaterThan(z, 0, "Must have some depth")
    }
    
    func testNodeBoundsFinding() throws {
        printStart()
        
        let parsed = try Parser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            bundle
                .newGrid()
                .withFileName(bundle.testFile.lastPathComponent)
                .consume(rootSyntaxNode: parsed.root)
        }
        
        let testGrid = newGrid()
        let testClass = try XCTUnwrap(testGrid.semanticInfoMap.classes.first, "Must have id to test")
        
        let computing = BoxComputing()
        testGrid
            .semanticInfoMap
            .doOnAssociatedNodes(testClass.key, testGrid.tokenCache) { info, nodes in
                computing.consumeNodeSet(Set(nodes), convertingTo: nil)
            }
        print(computing.bounds)
        
        printEnd()
    }
    
    func testFileBrowser() throws {
        let testFile = bundle.testFile
        let testPathStart = testFile
        let testPathParent = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let scopeStart = FileBrowser.Scope.file(testPathStart)
        let scopeParent = FileBrowser.Scope.file(testPathParent)
        
        let browser = FileBrowser()
        browser.scopes.append(scopeParent)
        
        let depth = browser.distanceToRoot(scopeStart)
        
        print("Depth: \(depth)")
        XCTAssertEqual(depth, 3, "Calls to parent and depth count must match")
    }
    
    //    func testRewriting() throws {
    //        let rewriter = TraceCapturingRewriter()
    //        let parsed = try! Parser.parse(bundle.testFileRaw)
    //        let rewritten = rewriter.visit(parsed)
    //        let rewrittenAgain = rewriter.visit(rewritten)
    //        XCTAssertEqual(rewritten.description, rewrittenAgain.description, "Rewrites should always result in the save end string")
    //
    //        let fileRewriter = TraceFileWriter()
    //        fileRewriter.addTracesToFile(bundle.testFileRaw)
    //    }
    //
    //    func test__RewritingAll() throws {
    //        let fileRewriter = TraceFileWriter()
    //
    //        printStart()
    //        let root = TestBundle.rewriteDirectories.first!
    //        let finder = TracingFileFinder()
    //
    //        finder.findFiles(root).forEach { path in
    //            fileRewriter.addTracesToFile(path)
    //        }
    //
    //        printEnd()
    //    }
    
    func testSnapping_EasyRight() throws {
        let snapping = WorldGridSnapping()
        
        
        let firstGrid = bundle.newGrid()
        let second_toRightOfFirst = bundle.newGrid()
        let third_toRightOfSecond = bundle.newGrid()
        
        print("connect first[\(firstGrid.id)] to second[\(second_toRightOfFirst.id)]")
        snapping.connect(sourceGrid: firstGrid, to: .right(second_toRightOfFirst))
        print("connect second to third[\(third_toRightOfSecond.id)]")
        snapping.connect(sourceGrid: second_toRightOfFirst, to: .right(third_toRightOfSecond))
        
        print("finding relative grids..")
        let firstRelative = try XCTUnwrap(snapping.gridsRelativeTo(firstGrid).first,
                                          "Must find relative grid immediately")
        guard case WorldGridSnapping.RelativeGridMapping.right = firstRelative else {
            XCTFail("Where did \(firstRelative) come from?")
            return
        }
        print("found: \(firstRelative.targetGrid.id)")
        
        let secondRelative = try XCTUnwrap(snapping.gridsRelativeTo(firstRelative.targetGrid).first,
                                           "Must find relative grid immediately")
        guard case WorldGridSnapping.RelativeGridMapping.right = secondRelative else {
            XCTFail("Where did \(secondRelative) come from???")
            return
        }
        print("relative: \(secondRelative.targetGrid.id)")
        
        print("checking targets align with snapping results...")
        XCTAssert(firstRelative.targetGrid === second_toRightOfFirst)
        XCTAssert(secondRelative.targetGrid === third_toRightOfSecond)
        print("sweet.")
    }
    
    func stats(_ testGrid: CodeGrid) {
        let testGridWidth = testGrid.lengthX
        let testGridHeight = testGrid.lengthY
        let testGridLength = testGrid.lengthZ
        let testGridCenter = testGrid.centerPosition
        
        let gridInfo = """
        ---
        Reported from grid: \(testGrid.fileName)
        gridWidth : \(testGridWidth), gridHeight:\(testGridHeight), gridLength:\(testGridLength),
        gridCenter: \(testGridCenter)
        """
        print(gridInfo)
        
        let manualWidth = BoundsWidth(testGrid.bounds)
        let manualHeight = BoundsHeight(testGrid.bounds)
        let manualLength = BoundsLength(testGrid.bounds)
        let manualCenter = testGrid.centerPosition
        let manualCenterConverted = testGrid.rootNode.convertPosition(manualCenter, to: testGrid.rootNode.parent)
        let manualInfo = """
        'Manual' Calculation
        manualWidth   : \(manualWidth),   manualHeight:          \(manualHeight), manualLength:\(manualLength)
        manualCenter  : \(manualCenter),  manualCenterConverted: \(manualCenterConverted)
        """
        print(manualInfo)
    }
    
    func testPositions() throws {
        let parsed = try Parser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            bundle.newGrid()
                .withFileName(bundle.testFile.lastPathComponent)
                .consume(rootSyntaxNode: parsed.root)
        }
        let testGrid = newGrid()
        var (deltaX, deltaY, deltaZ) = (Float.zero, Float.zero, Float.zero)
        
        printStart()
        print("start: ----")
        print(testGrid.dumpstats)
        
        XCTAssertEqual(testGrid.position, .zero, "Must start at 0,0,0")
        
        testGrid.setLeading(0)
        testGrid.setTop(0)
        testGrid.setBack(0)
        print("after translate: ----")
        print(testGrid.dumpstats)
        
        // Values should be equal after setting
        deltaX = testGrid.localLeading
        deltaY = testGrid.localTop
        deltaZ = testGrid.localBack
        XCTAssertEqual(deltaX, 0.0, "Error should be within Metal Float accuracy")
        XCTAssertEqual(deltaY, 0.0, "Error should be within Metal Float accuracy")
        XCTAssertEqual(deltaZ, 0.0, "Error should be within Metal Float accuracy")
        
        let alignedGrid = newGrid()
        print("new grid: ----")
        print(alignedGrid.dumpstats)
        alignedGrid.setLeading(testGrid.localTrailing)
        
        print("after align: ----")
        print(alignedGrid.dumpstats)
        
        printEnd()
    }
    
    func testMeasuresAndSizes() throws {
        //        let parsed = try Parser.parse(bundle.testFile)
        let parsed = Parser.parse(source: TestBundle.RawCode.threeLine)
        func newGrid() -> CodeGrid {
            bundle.newGrid()
                .consume(rootSyntaxNode: parsed.root)
        }
        
        let testGrid = newGrid()
        stats(testGrid)
        XCTAssert(testGrid.lengthX > 0, "Should have some size")
        XCTAssertEqual(testGrid.rootNode.position, .zero, "Must start at zero position for test")
        
        // Test initial sizing works
        let testGridWidth = testGrid.lengthX
        let testGridHeight = testGrid.lengthY
        let testGridLength = testGrid.lengthZ
        
        let centerPosition = testGrid.centerPosition
        var centerX = centerPosition.x
        var centerY = centerPosition.y
        var centerZ = centerPosition.z
        
        let expectedCenterX = testGrid.localLeading + testGridWidth / 2.0
        let expectedCenterY = testGrid.localTop - testGridHeight / 2.0
        let expectedCenterZ = testGrid.localFront - testGridLength / 2.0
        
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
        doTranslateTest(7.1)
        doTranslateTest(7.2)
        doTranslateTest(1000)
        doTranslateTest(-10000)
        doTranslateTest(194.231)
        
        // Move node, then test the expected position comes back
        func doTranslateTest(_ delta: VectorFloat) {
            testGrid.translated(dX: delta, dY: delta, dZ: delta)
            
            stats(testGrid)
            
            let newCenterPosition = testGrid.centerPosition
            let newCenterX = newCenterPosition.x
            let newCenterY = newCenterPosition.y
            let newCenterZ = newCenterPosition.z
            
            let newExpectedCenterX = centerX + delta
            let newExpectedCenterY = centerY + delta
            let newExpectedCenterZ = centerZ + delta
            
            // Current measurements and position have a precision of about 3-4 places
            XCTAssertEqual(newCenterX, newExpectedCenterX, accuracy: 0.0001, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterY, newExpectedCenterY, accuracy: 0.0001, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterZ, newExpectedCenterZ, accuracy: 0.0001, "Error should be within Metal Float accuracy")
            
            centerX = newExpectedCenterX
            centerY = newExpectedCenterY
            centerZ = newExpectedCenterZ
            
            let newBounds = testGrid.rootNode.bounds
            let newBoundsWidth = BoundsWidth(newBounds) * DeviceScale
            let newBoundsHeight = BoundsHeight(newBounds) * DeviceScale
            let newBoundsLength = BoundsLength(newBounds) * DeviceScale
            let newBoundsCenter = testGrid.rootNode.boundsCenterPosition
            
            let sizeDeltaX = abs(testGridWidth - newBoundsWidth)
            let sizeDeltaY = abs(testGridHeight - newBoundsHeight)
            let sizeDeltaZ = abs(testGridLength - newBoundsLength)
            
            XCTAssertLessThanOrEqual(sizeDeltaX, 0.001, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(sizeDeltaY, 0.001, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(sizeDeltaZ, 0.001, "Error should be within 1 point")
            
            let boundsDeltaX = abs(newCenterX - newBoundsCenter.x)
            let boundsDeltaY = abs(newCenterY - newBoundsCenter.y)
            let boundsDeltaZ = abs(newCenterZ - newBoundsCenter.z)
            
            XCTAssertLessThanOrEqual(boundsDeltaX, 0.001, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(boundsDeltaY, 0.001, "Error should be within 1 point")
            XCTAssertLessThanOrEqual(boundsDeltaZ, 0.001, "Error should be within 1 point")
        }
    }
    
    func testSnapping_Complicated() throws {
        let parsed = try Parser.parse(bundle.testFile)
        var allGrids = [CodeGrid]()
        func newGrid() -> CodeGrid {
            let newGrid = bundle.newGrid()
                .consume(rootSyntaxNode: parsed.root)
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
        
        var totalLengthX: VectorFloat = firstGrid.lengthX
        func sumLength(grid: CodeGrid, _ direction: SelfRelativeDirection, _ op: @escaping () -> Void ) {
            snapping.iterateOver(grid, direction: direction) { _, grid, stop in
                print(grid.id, totalLengthX)
                totalLengthX += grid.lengthX
                op()
            }
        }
        printStart()
        sumLength(grid: focusedGrid, .forward) { linkCount.fulfill() }
        wait(for: [linkCount], timeout: 1)
        printEnd()
        
        let expectedLengthX = allGrids.reduce(into: VectorFloat(0)) { length, grid in
            length += grid.lengthX
        }
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
        
        totalLengthX = firstGrid.lengthX
        printStart()
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX, "Measured lengths must match")
        printEnd()
        
        let oneGridLength = allGrids[2].lengthX
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[2])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength, "Retaining detach should do the retaining thing")
        printEnd()
        
        printStart()
        let second = allGrids[7].lengthX
        totalLengthX = second
        snapping.detachRetaining(allGrids[7])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength - second, accuracy: 0.0001, "Retaining detach should do the retaining thing")
        printEnd()
        
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[4])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength - oneGridLength - oneGridLength, accuracy: 0.0001, "Retaining detach should do the retaining thing")
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
