//
//  CodeGridTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import Foundation
import BitHandling
import MetalLinkHeaders
import MetalLink
import SwiftGlyph
@testable import SwiftGlyphsHI

let ACCURACY: VectorFloat = 0.001

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
    
    func testFileRecursion() throws {
        let path = try XCTUnwrap(URL(string: bundle.rootDirectory), "Must have valid root directory")
        FileBrowser.recursivePaths(path).forEach {
            print("\($0.description)")
        }
    }
    
    func testLinkParenting() throws {
        let link = GlobalInstances.defaultLink
        let builder = GlobalInstances.gridStore.builder
        
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
        let builder = GlobalInstances.gridStore.builder
        
        func consumed(_ url: URL) -> GlyphCollectionSyntaxConsumer {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: url)
            return consumer
        }
        
        let testGrid1 = consumed(bundle.testFile).targetGrid
        let testGrid2 = consumed(bundle.testFile).targetGrid
        
        testGrid2.position = LFloat3(123_456, 654_321, 987_654)
        
        // call multiple times to make sure it isn't additive.
        testGrid2.setLeading(testGrid1.leading)
        testGrid2.setLeading(testGrid1.leading)
        testGrid2.setLeading(testGrid1.leading)
        XCTAssertEqual(testGrid2.leading, testGrid1.leading, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setLeading(testGrid1.trailing)
        XCTAssertEqual(testGrid2.leading, testGrid1.trailing, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setTrailing(testGrid1.trailing)
        XCTAssertEqual(testGrid2.trailing, testGrid1.trailing, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setTop(testGrid1.top)
        XCTAssertEqual(testGrid2.top, testGrid1.top, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setBottom(testGrid1.bottom)
        XCTAssertEqual(testGrid2.bottom, testGrid1.bottom, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setFront(testGrid1.front)
        XCTAssertEqual(testGrid2.front, testGrid1.front, accuracy: ACCURACY, "There should be no offset after setting")
        
        testGrid2.setBack(testGrid1.back)
        XCTAssertEqual(testGrid2.back, testGrid1.back, accuracy: ACCURACY, "There should be no offset after setting")
    }
    
    func testLinkNodeStatsForMultiCollection() throws {
//        let builder = GlobalInstances.gridStore.builder
        
        // NOTE: HEADS: README:
        // This is specifically checking node cache bounds, don't use the shared one.
        // The tests are parallel by default and I dont mind doing this for now before deps.
        let cache = CodeGridTokenCache()
        let collection = try GlyphCollection.init(
            link: GlobalInstances.defaultLink,
            linkAtlas: GlobalInstances.defaultAtlas
        )
        let testGrid = GlyphCollectionSyntaxConsumer(
            targetGrid: CodeGrid(
                rootNode: collection,
                tokenCache: cache
            )
        )
        .consumeText(text: "A")
        .withFileName(bundle.testFile.lastPathComponent)
        .removeBackground()
        
        XCTAssertFalse(
            testGrid.tokenCache.isEmpty(),
            "TokenCache must have built nodes"
        )
        
        func performChecks() {
            var testBounds = Bounds.forBaseComputing
            testGrid.tokenCache.doOnEach { id, nodeSet in
                for node in nodeSet {
                    XCTAssertTrue(node.contentBounds.width > 0, "Glyph nodes usually have some width")
                    XCTAssertTrue(node.contentBounds.height > 0, "Glyph nodes usually have some height")
                    XCTAssertTrue(node.contentBounds.length > 0, "Glyph nodes usually have some depth")
                    
                    // TODO: WARNING! CAREFUL! OH NO! `.bounds` is still rocky!
                    // node.bounds gave local bounds. Without calling convert directly,
                    // the glyphs aren't properly positioned. This is a weird test,
                    // as it's checking that nodes and grids align after blitting,
                    // but it's caught a bunch of stuff so far so I'm keeping it.
                    // For now, this behavior is mostly OK, but be warned when
                    // when interacting the glyph node positioning directly.
                    testBounds.union(with: node.computeLocalBounds())
                }
            }
            
            // NOTE: This test will fail if whitespaces/newlines aren't added to constants.
            // The above bounds are computed with all nodes.
            print("computed grid vector size: ",        testGrid.sizeBounds.size)
            print("computed grid bounds vector size: ", testGrid.bounds.size)
            print("computed test bounds vector size: ", testBounds.size)
            
            print("grid world bounds: ", testGrid.bounds)
            print("test world bounds: ", testBounds)
            
            func compare(_ l: Bounds, _ r: Bounds) {
                XCTAssertEqual(l.min.x, r.min.x, accuracy: ACCURACY, "min.x")
                XCTAssertEqual(l.min.y, r.min.y, accuracy: ACCURACY, "min.y")
                XCTAssertEqual(l.min.z, r.min.z, accuracy: ACCURACY, "min.z")
                XCTAssertEqual(l.max.x, r.max.x, accuracy: ACCURACY, "max.x")
                XCTAssertEqual(l.max.y, r.max.y, accuracy: ACCURACY, "max.y")
                XCTAssertEqual(l.max.z, r.max.z, accuracy: ACCURACY, "max.z")
            }
            compare(testGrid.bounds, testBounds)
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
        
        let builder = GlobalInstances.gridStore.builder
        let testGrid = builder.createConsumerForNewGrid()
            .consume(url: bundle.testFile)
            .withFileName(bundle.testFile.lastPathComponent)
        
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
        
        let builder = GlobalInstances.gridStore.builder
        
        func newGrid() -> CodeGrid {
            builder.createConsumerForNewGrid()
                .consume(url: bundle.testFile)
                .withFileName(bundle.testFile.lastPathComponent)
        }
        
        let testGrid = newGrid()
        let testClass = try XCTUnwrap(testGrid.semanticInfoMap.classes.first, "Must have id to test")
        
        var computing = Bounds.forBaseComputing
        testGrid
            .semanticInfoMap
            .doOnAssociatedNodes(testClass.key, testGrid.tokenCache) { info, nodes in
                nodes.forEach {
                    computing.union(with: $0.bounds)
                }
            }
        print(computing)
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
        let builder = GlobalInstances.gridStore.builder
        func newGrid() -> CodeGrid {
            builder.createConsumerForNewGrid()
                .consume(url: bundle.testFile)
                .withFileName(bundle.testFile.lastPathComponent)
        }
        
        let firstGrid = newGrid()
        let second_toRightOfFirst = newGrid()
        let third_toRightOfSecond = newGrid()
        
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
        
        let manualWidth = testGrid.bounds.width
        let manualHeight = testGrid.bounds.height
        let manualLength = testGrid.bounds.length
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
        let builder = GlobalInstances.gridStore.builder
        func newGrid() -> CodeGrid {
            builder.createConsumerForNewGrid()
                .consume(url: bundle.testFile)
                .withFileName(bundle.testFile.lastPathComponent)
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
        deltaX = testGrid.leading
        deltaY = testGrid.top
        deltaZ = testGrid.back
        XCTAssertEqual(deltaX, 0.0, "Error should be within Metal Float accuracy")
        XCTAssertEqual(deltaY, 0.0, "Error should be within Metal Float accuracy")
        XCTAssertEqual(deltaZ, 0.0, "Error should be within Metal Float accuracy")
        
        let alignedGrid = newGrid()
        print("new grid: ----")
        print(alignedGrid.dumpstats)
        alignedGrid.setLeading(testGrid.trailing)
        
        print("after align: ----")
        print(alignedGrid.dumpstats)
        
        printEnd()
    }
    
    func testMeasuresAndSizes() throws {
        let builder = GlobalInstances.gridStore.builder
        func newGrid() -> CodeGrid {
            builder.createConsumerForNewGrid()
                .consumeText(text: TestBundle.RawCode.A)
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
        
        let expectedCenterX = testGrid.leading + testGridWidth / 2.0
        let expectedCenterY = testGrid.top - testGridHeight / 2.0
        let expectedCenterZ = testGrid.front - testGridLength / 2.0
        
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
//        doTranslateTest(-5)
//        doTranslateTest(-4)
//        doTranslateTest(-3)
//        doTranslateTest(-2)
//        doTranslateTest(-1)
//        doTranslateTest(0)
//        doTranslateTest(1)
//        doTranslateTest(2)
//        doTranslateTest(3)
//        doTranslateTest(4)
//        doTranslateTest(5)
//        doTranslateTest(6)
//        doTranslateTest(7.1)
//        doTranslateTest(7.2)
//        doTranslateTest(1000)
//        doTranslateTest(-10000)
//        doTranslateTest(194.231)
        
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
            XCTAssertEqual(newCenterX, newExpectedCenterX, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterY, newExpectedCenterY, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterZ, newExpectedCenterZ, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            
            centerX = newExpectedCenterX
            centerY = newExpectedCenterY
            centerZ = newExpectedCenterZ
            
            let newBounds       = testGrid.rootNode.bounds
            let newBoundsWidth  = newBounds.width * DeviceScale
            let newBoundsHeight = newBounds.height * DeviceScale
            let newBoundsLength = newBounds.length * DeviceScale
            let newBoundsCenter = testGrid.rootNode.boundsCenterPosition
            
            XCTAssertEqual(testGridWidth, newBoundsWidth, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(testGridHeight, newBoundsHeight, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(testGridLength, newBoundsLength, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            
            XCTAssertEqual(newCenterX, newBoundsCenter.x, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterY, newBoundsCenter.y, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
            XCTAssertEqual(newCenterZ, newBoundsCenter.z, accuracy: ACCURACY, "Error should be within Metal Float accuracy")
        }
    }
    
    func testSnapping_Complicated() throws {
        var allGrids = [CodeGrid]()
        let builder = GlobalInstances.gridStore.builder
        func newGrid() -> CodeGrid {
            let newGrid = builder.createConsumerForNewGrid()
                .consume(url: bundle.testFile)
                .withFileName(bundle.testFile.lastPathComponent)
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
