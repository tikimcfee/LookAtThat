//
//  LookAtThat-TracingTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/3/22.
//

import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
@testable import LookAtThat_AppKit

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
    
    func testTreeSitter() throws {
        let language = Language(language: tree_sitter_swift())
        
        let parser = Parser()
        try parser.setLanguage(language)
        
        let testFile = try String(contentsOf: bundle.testFile)
        let tree = parser.parse(testFile)!
        
        // find the SPM-packaged queries
        let queryURL = Bundle.main
            .resourceURL!
            .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
            .appendingPathComponent("Contents/Resources/queries/locals.scm")
        
        let query = try language.query(contentsOf: queryURL)
        
        let cursor = query.execute(node: tree.rootNode!)
        
        // the performance of nextMatch is highly dependent on the nature of the queries,
        // language grammar, and size of input
        while let match = cursor.next() {
            match.captures.forEach {
                print(">> match:")
                let message = """
                >> \($0.name ?? "!! name-missing")
                \(testFile[Range($0.node.range, in: testFile)!])
                
                """
                print(message)
            }
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
    
    func testTracing() throws {
        let tracer = TracingRoot.shared
        tracer.setupTracing()
        tracer.state.traceWritesEnabled = true
        
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        
        let grid = bundle.newGrid()
            .applying { _ in printStart() }
            .consume(rootSyntaxNode: sourceSyntax)
        printEnd()
        
        let _ = SemanticMapTracer.wrapForLazyLoad(
            sourceGrids: [grid],
            sourceTracer: tracer
        )
        tracer.commitMappingState()
        
        //        let firstThread = try XCTUnwrap(tracer.capturedLoggingThreads.keys.first, "Expected at least one log thread")
        //        let logs = try XCTUnwrap(firstThread.getTraceLogs())
        
        let _ = try XCTUnwrap(tracer.capturedLoggingQueues.keys.first, "Expected at least one log queue")
        let logs = try XCTUnwrap(tracer.getCurrentQueueTraceLogs())
        
        XCTAssertGreaterThan(logs.count, 0, "Expected at least 1 trace result")
    }

    func testTracingGroup() throws {
        let group = PersistentThreadGroup()
        PersistentThreadTracer.SHOULD_WRITE = true
        let tracer = try XCTUnwrap(
            group.tracer(for: currentQueueName()),
            "Must recreate from the same thread during runtime"
        )
        tracer.eraseTargetAndReset()
        group.eraseTraceMap()
        
        let testWrites = (0..<12_512)
        for _ in testWrites {
            group.multiplextNewLine(
                thread: Thread.current,
                queueName: currentQueueName(),
                line: .random
            )
        }
        print("Wrote: \(testWrites.upperBound)")
        print("CachedIds: \(group.sharedSignatureMap.persistedBiMap.keysToValues.keys.count)")
        print("Tracer reports count: \(tracer.count)")
        XCTAssertEqual(tracer.count, testWrites.upperBound, "All writes must be recorded")
        
        let commitDidSucceed = group.commitTraceMapToTarget()
        XCTAssertTrue(commitDidSucceed, "Group must succeed in writing to target file")
        let data = try Data(contentsOf: PersistentThreadGroup.defaultMapFile)
        print("Final traceIdMap: \(data)")
        XCTAssertGreaterThan(data.count, 0, "Commited target map must have some data written")
        let allTraceFileSizes = totalTraceFilesByteCount
        print("Final id list totals: \(allTraceFileSizes) bytes || \(Double(allTraceFileSizes) / Double(1024))kb")
        
        let groupMapKeyCount = group.sharedSignatureMap.persistedBiMap.keysToValues.keys.count
        group.reloadTraceMap()
        let reloadedKeyCount = group.sharedSignatureMap.persistedBiMap.keysToValues.keys.count
        XCTAssertEqual(groupMapKeyCount, reloadedKeyCount, "Reload must not mutate data")
    }
    
    var totalTraceFilesByteCount: Int {
        AppFiles.allTraceFiles().reduce(into: 0) { total, url in
            let data = try? Data(contentsOf: url)
            let count = data?.count ?? 0
            print("\(url): \(count)")
            total += data?.count ?? 0
        }
    }
}
