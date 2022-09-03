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
import Foundation
@testable import LookAtThat_AppKit

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
    
    func testSemanticInfo() throws {
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        
        for token in sourceSyntax.tokens {
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
    
    func testLinkNodeStats() throws {
        let link = GlobalInstances.defaultLink
        let builder = CodeGridGlyphCollectionBuilder(
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
            let testBounds = BoundsComputing()
            testGrid.tokenCache.doOnEach { id, nodeSet in
                //            printSeparator()
                //            print("token", id)
                for node in nodeSet {
                    XCTAssertTrue(node.width > 0, "Glyph nodes usually have some width")
                    XCTAssertTrue(node.height > 0, "Glyph nodes usually have some height")
                    XCTAssertTrue(node.depth > 0, "Glyph nodes usually have some depth")
                    testBounds.consumeBounds(node.boundsInParent)
                    //                print("\t", node.id)
                    //                print("\tpos ", node.position)
                    //                print("\tsize", node.size)
                    //                print("\tbox ", node.manualBoundingBox)
                }
            }
            // NOTE: This test will fail if whitespaces/newlines aren't added to constants.
            // The above bounds are computed with all nodes.
            print("grid size: ", BoundsSize(testGrid.rootNode.manualBoundingBox))
            print("test size: ", BoundsSize(testBounds.bounds))
            
            print("grid bounds: ", testGrid.rootNode.manualBoundingBox)
            print("test bounds: ", testBounds.bounds)
            XCTAssertEqual(
                testBounds.bounds.min,
                testGrid.rootNode.manualBoundingBox.min,
                "An unmoved collection has the same bounds as its children"
            )
            
            XCTAssertEqual(
                testBounds.bounds.max,
                testGrid.rootNode.manualBoundingBox.max,
                "An unmoved collection has the same bounds as its children"
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
        
        let parsed = try SyntaxParser.parse(bundle.testFile)
        let testGrid = bundle.newGrid()
            .withFileName(bundle.testFile.lastPathComponent)
            .consume(rootSyntaxNode: parsed.root)
        
//        let testClass = try XCTUnwrap(
//            testGrid.semanticInfoMap.classes.first,
//            "Must have id to test"
//        )
        
        let (x, y, z) = (
            testGrid.measures.lengthX,
            testGrid.measures.lengthY,
            testGrid.measures.lengthZ
        )
        
        XCTAssertGreaterThan(x, 0, "Must have some width")
        XCTAssertGreaterThan(y, 0, "Must have some height")
        XCTAssertGreaterThan(z, 0, "Must have some depth")
    }
    
    func testNodeBoundsFinding() throws {
        printStart()
        
        let parsed = try SyntaxParser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            bundle
                .newGrid()
                .withFileName(bundle.testFile.lastPathComponent)
                .consume(rootSyntaxNode: parsed.root)
        }
        
        let testGrid = newGrid()
        let testClass = try XCTUnwrap(testGrid.semanticInfoMap.classes.first, "Must have id to test")

        let computing = BoundsComputing()
        testGrid
            .semanticInfoMap
            .doOnAssociatedNodes(testClass.key, testGrid.tokenCache) { info, nodes in
                computing.consumeNodeSet(nodes, convertingTo: nil)
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
//        let parsed = try! SyntaxParser.parse(bundle.testFileRaw)
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
        let testGridWidth = testGrid.measures.lengthX
        let testGridHeight = testGrid.measures.lengthY
        let testGridLength = testGrid.measures.lengthZ
        let testGridCenter = testGrid.measures.centerPosition

        let gridInfo = """
        ---
        Reported from grid: \(testGrid.fileName)
        gridWidth : \(testGridWidth), gridHeight:\(testGridHeight), gridLength:\(testGridLength),
        gridCenter: \(testGridCenter)
        """
        print(gridInfo)
        
        let manualWidth = BoundsWidth(testGrid.rootNode.manualBoundingBox)
        let manualHeight = BoundsHeight(testGrid.rootNode.manualBoundingBox)
        let manualLength = BoundsLength(testGrid.rootNode.manualBoundingBox)
        let manualCenter = testGrid.rootNode.boundsCenterPosition
        let manualCenterConverted = testGrid.rootNode.convertPosition(manualCenter, to: testGrid.rootNode.parent)
        let manualInfo = """
        ---
        'Manual' Calculation
        manualWidth   : \(manualWidth),   manualHeight:          \(manualHeight), manualLength:\(manualLength)
        manualCenter  : \(manualCenter),  manualCenterConverted: \(manualCenterConverted)
        """
        print(manualInfo)
    }
    
    func testPositions() throws {
        let parsed = try SyntaxParser.parse(bundle.testFile)
        func newGrid() -> CodeGrid {
            bundle.newGrid()
                .withFileName(bundle.testFile.lastPathComponent)
                .consume(rootSyntaxNode: parsed.root)
        }
        let testGrid = newGrid()
        var (deltaX, deltaY, deltaZ) = (Float.zero, Float.zero, Float.zero)
        
        printStart()
        print("start: ----")
        print(testGrid.measures.dumpstats)

        XCTAssertEqual(testGrid.measures.position, .zero, "Must start at 0,0,0")
        
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
//        let parsed = try SyntaxParser.parse(bundle.testFile)
        let parsed = try SyntaxParser.parse(source: TestBundle.RawCode.threeLine)
        func newGrid() -> CodeGrid {
            bundle.newGrid()
                .consume(rootSyntaxNode: parsed.root)
        }
        
        let testGrid = newGrid()
        stats(testGrid)
        XCTAssert(testGrid.measures.lengthX > 0, "Should have some size")
        XCTAssertEqual(testGrid.rootNode.position, .zero, "Must start at zero position for test")
        
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
            
            // Current measurements and position have a precision of about 3-4 places
            XCTAssertEqual(newCenterX, newExpectedCenterX, accuracy: 0.001, "Error should be within 1 point")
            XCTAssertEqual(newCenterY, newExpectedCenterY, accuracy: 0.001, "Error should be within 1 point")
            XCTAssertEqual(newCenterZ, newExpectedCenterZ, accuracy: 0.001, "Error should be within 1 point")
            
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
        
        let oneGridLength = allGrids[2].measures.lengthX
        totalLengthX = oneGridLength
        printStart()
        snapping.detachRetaining(allGrids[2])
        sumLength(grid: allGrids.last!, .backward, { })
        XCTAssertEqual(totalLengthX, expectedLengthX - oneGridLength, "Retaining detach should do the retaining thing")
        printEnd()
        
        printStart()
        let second = allGrids[7].measures.lengthX
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
