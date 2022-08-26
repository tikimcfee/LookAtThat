//
//  LookAtThat-TracingTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/3/22.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import Foundation
@testable import LookAtThat_AppKit

class LookAtThat_TracingTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
        
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
    }
    
    func testDeepRecursion() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
//        let enumerator = try XCTUnwrap(FileManager.default.enumerator(atPath: rootUrl.path), "Need enumerator")
        
        printStart()
        
        rootUrl.enumeratedChildren().forEach { print($0) }
        
        printEnd()
    }
    
    func testClassCollection() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
        printStart()
        
        
        let dummyGrid = bundle.gridParser.createNewGrid()
        let visitor = FlatteningVisitor(
            target: dummyGrid.codeGridSemanticInfo,
            builder: dummyGrid.semanticInfoBuilder
        )
        
        try rootUrl.enumeratedChildren().forEach { url in
            guard !url.isDirectory else {
                return
            }
            let sourceFile = try XCTUnwrap(bundle.gridParser.loadSourceUrl(url), "Must render syntax from file")
            let sourceSyntax = Syntax(sourceFile)
            visitor.walkRecursiveFromSyntax(sourceSyntax)
        }
        
        let classes = dummyGrid.codeGridSemanticInfo.classes.keys.compactMap {
            dummyGrid.codeGridSemanticInfo.semanticsLookupBySyntaxId[$0]
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
        
        let grid = bundle.gridParser.createNewGrid()
            .applying { _ in printStart() }
            .consume(rootSyntaxNode: sourceSyntax)
            .sizeGridToContainerNode()
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
    
    func testFileBackArrays() throws {
        let traceFile = bundle.testTraceFile
        let traceFileSpec = AppFiles.createTraceIDFile(named: "test-spec")
        let idMap = TraceLineIDMap()
        
        let specFileWriter = AppendingStore(targetFile: traceFileSpec)
        specFileWriter.cleanFile()
        
        var startingLineCount = 0
        //        var testStop = 10
        SplittingFileReader(targetURL: traceFile)
            .cancellableRead { newLine, shouldStop in
                guard let generatedTraceId = try? XCTUnwrap(idMap.insertRawLine(newLine), "Must get ID from new trace line")
                else {
                    shouldStop = true
                    return
                }
                specFileWriter.appendText(generatedTraceId.uuidString)
                startingLineCount += 1
                
                //                testStop -= 1
                //                shouldStop = testStop <= 0
            }
        
        printStart()
        print("Trace reads from: \(traceFile)")
        print("Spec  reads from: \(traceFileSpec)")
        print("Map: \(idMap.persistedBiMap.keysToValues.keys.count) keys")
        print("Had lines: \(startingLineCount)")
        
        let uuidArray = try XCTUnwrap(
            FileUUIDArray.from(fileURL: traceFileSpec)
        )
        
        print("File array: start  \(uuidArray.startIndex)")
        print("File array: end    \(uuidArray.endIndex)")
        print("File array: count  \(uuidArray.count)")
        
        
        let finalData = try Data(contentsOf: traceFileSpec)
        let originalData = try Data(contentsOf: traceFile)
        print("End spec file size: \(finalData.kb)")
        print("Original file size: \(originalData.kb)")
        
        let enodedMap = try idMap.encodeValues()
        print("Encoded new map size: \(enodedMap)")
        
        let decodedMap = try TraceLineIDMap.decodeFrom(enodedMap)
        print("Decoded map keys: \(decodedMap.persistedBiMap.valuesToKeys.keys.count)")
        
        let recodedMap = try decodedMap.encodeValues()
        XCTAssertEqual(enodedMap.count, recodedMap.count, "ID map must be resilient to reencode")
        
        print("Checking for all matched lines...")
        var finalMatchedCount = 0
        for case .some(let uuid) in uuidArray {
            let _ = try XCTUnwrap(decodedMap[uuid], "Must have mapped trace for \(uuid)")
            finalMatchedCount += 1
        }
        print("Total lines matched: \(finalMatchedCount)")
        XCTAssertEqual(finalMatchedCount, startingLineCount, "All lines must be matchable from decoded store")
        
        printEnd()
    }
    
    func testTracingGroup() throws {
        printStart()
        let group = PersistentThreadGroup()
//        PersistentThreadTracer.AllWritesEnabled = true
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
        
        printEnd()
    }
    
    func testTracingMulti() throws {
        printStart()
        let tracer = TracingRoot.shared
        tracer.removeAllTraces()
        tracer.removeMapping()
        tracer.state.traceWritesEnabled = true
        tracer.setupTracing()
        
        let rootDirectory = try XCTUnwrap(bundle.testSourceDirectory)
        let awaitRender = expectation(description: "Version three rendered")
        bundle.gridParser.__versionThree_RenderConcurrent(rootDirectory) { _ in
            print("Receiver emitted versionThree")
            awaitRender.fulfill()
        }
        wait(for: [awaitRender], timeout: 60)
        
        tracer.commitMappingState()
        let _ = SemanticMapTracer.wrapForLazyLoad(
            sourceGrids: bundle.gridParser.gridCache.cachedGrids.values.map { $0.source },
            sourceTracer: tracer
        )
        
        let allTraceFileSizes = totalTraceFilesByteCount
        print("ID list total: \(allTraceFileSizes) bytes || \(allTraceFileSizes.kb)kb")
        
        let data = try Data(contentsOf: PersistentThreadGroup.defaultMapFile)
        print("traceIdMap   : \(data.count) bytes || \(data.kb)kb")
        
        printEnd()
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
