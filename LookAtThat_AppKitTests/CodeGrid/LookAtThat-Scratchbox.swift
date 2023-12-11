//
//  LookAtThat-Scratchbox.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 8/16/22.
//

import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import MetalLink
import MetalLinkHeaders
import MetalLinkResources
import BitHandling
import SwiftGlyph
@testable import LookAtThat_AppKit

class LookAtThat_ScratchboxTests: XCTestCase {
    var bundle: TestBundle!
    var device: MTLDevice!
    var customMTKView: CustomMTKView!
    var metalLink: MetalLink!
    var atlas: MetalLinkAtlas!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        
        bundle = TestBundle()
        try bundle.setUpWithError()
        
        guard let device = MTLCreateSystemDefaultDevice()
        else { throw CoreError.noMetalDevice }
        
        self.device = device
        self.customMTKView = CustomMTKView(frame: .zero, device: device)
        self.metalLink = try MetalLink(view: customMTKView)
        self.atlas = GlobalInstances.defaultAtlas
        
        printStart()
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
        
        printEnd()
    }
    
    func testSplittingFileReader() async throws {
//        let rawString = try String(contentsOf: bundle.testFile)
//        let reader = SplittingFileReader(targetURL: bundle.testFile)
//        let stream = reader.asyncLineStream()
//        
//        let copyTarget = bundle.testFile.appendingPathExtension("__text")
//        if FileManager.default.fileExists(atPath: copyTarget.path())
//            && FileManager.default.isDeletableFile(atPath: copyTarget.path()) {
//            try FileManager.default.removeItem(at: copyTarget)
//        }
//        try FileManager.default.copyItem(
//            at: bundle.testFile,
//            to: copyTarget
//        )
        XCTFail("not enabled")
    }
    
    func testBufferReadWrite() throws {
        // PoC that the buffer can be bound to empty space and we still get back objects
        let instances = 100
        let buffer = try XCTUnwrap(metalLink.device.makeBuffer(
            length: InstancedConstants.memStride * instances,
            options: .storageModeManaged
        ))
        
        let firstPointer = buffer.boundPointer(as: InstancedConstants.self, count: instances)
        print(firstPointer[50])
        
        let testColorAdd = LFloat4(0.0, 0.3, 0.5, 0.0)
        firstPointer[50].addedColor = testColorAdd
        print(firstPointer[50])
        XCTAssertEqual(testColorAdd, firstPointer[50].addedColor, "Pointer must retain changes")
        
        let copiedBuffer = try XCTUnwrap(metalLink.device.makeBuffer(
            bytes: firstPointer,
            length: instances * 200,
            options: .storageModeManaged
        ))
        let secondPointer = copiedBuffer.boundPointer(as: InstancedConstants.self, count: instances)
        print(secondPointer[50])
        XCTAssertEqual(testColorAdd, secondPointer[50].addedColor, "Pointer must retain changes after copy")
    }
    
    func testBackingBuffer() throws {
        let backingBuffer = try BackingBuffer<InstancedConstants>(link: metalLink)
        XCTAssertEqual(backingBuffer.currentEndIndex, 0, "Should always start at 0 index")
        XCTAssertEqual(backingBuffer.count, 0, "Should have have a starting count of 0")
        var iterations = 0
        backingBuffer.forEach { _ in iterations += 1 }
        XCTAssertEqual(iterations, 0, "Initial buffer should not iterate")
        
        let initialSize = backingBuffer.currentBufferSize
        
        var instances = [InstancedConstants]()
        for index in 0..<backingBuffer.currentBufferSize {
            let next = try backingBuffer.createNext()
            instances.append(next)
            XCTAssertEqual(Int(next.bufferIndex), index, "Indices must align when creating from buffer")
        }
        
        _ = try backingBuffer.createNext()
        XCTAssertLessThan(initialSize, backingBuffer.currentBufferSize, "Buffer must properly resize itself")
        
        var afterResizeIterations = 0
        backingBuffer.forEach { _ in afterResizeIterations += 1 }
        XCTAssertEqual(afterResizeIterations, initialSize + 1, "Iteration must match buffer size")
        XCTAssertEqual(afterResizeIterations, backingBuffer.count, "Iteration must count all items")
    }
}
