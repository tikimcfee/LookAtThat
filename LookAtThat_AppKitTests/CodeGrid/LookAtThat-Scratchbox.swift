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
        let rawString = try String(contentsOf: bundle.testFile)
        let reader = SplittingFileReader(targetURL: bundle.testFile)
        let stream = reader.asyncLineStream()
        
        let copyTarget = bundle.testFile.appendingPathExtension("__text")
        if FileManager.default.isDeletableFile(atPath: copyTarget.path()) {
            try FileManager.default.removeItem(at: copyTarget)
        }
        
        try FileManager.default.copyItem(
            at: bundle.testFile,
            to: copyTarget
        )
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
    
    func testVertexRects() throws {
        var rects = [VertexRect]()
        let testLength = 10
        let testWidth = 100
        let testHeight = 100
        for _ in (0..<testLength) {
            for _ in (0..<testLength) {
                let rect = VertexRect()
                rect.width = testWidth
                rect.height = testHeight
                rects.append(rect)
            }
        }
        
        let intPacking = AtlasPacking<VertexRect>(width: 1000, height: 1000)
        rects.forEach { intPacking.packNextRect($0) }

        var expectedY = 0
        for (index, rect) in rects.striding(by: testLength).enumerated() {
            expectedY = index * testHeight
            XCTAssertEqual(rect.y, expectedY)
        }
    }
    
    func testUVRects() throws {
        guard let atlasTexture = device.makeTexture(
            descriptor: AtlasBuilder.canvasDescriptor
        ) else { throw LinkAtlasError.noTargetAtlasTexture }
        
        var uvCache = TextureUVCache()
        let sampleAtlasGlyphs = """
        ABCDEFGHIJ🥸KLMNOPQRSTUVWXYZ
        abcdefghijkl🤖mnopqrstuvwxyz
        12345🙀67890 -_+=/👾
        !@#$%^&*()[]\\;',./{}|:"<>?
        """.components(separatedBy: .newlines).joined()
        
        let textureBundles: [(GlyphCacheKey, MetalLinkGlyphTextureCache.Bundle)] =
            sampleAtlasGlyphs.lazy
                .map { GlyphCacheKey(source: $0, .red) }
                .compactMap {
                    guard let bundle = self.atlas.nodeCache.textureCache[$0]
                    else { return nil }
                    return ($0, bundle)
                }
        
        func atlasUVSize(
            for bundle: MetalLinkGlyphTextureCache.Bundle,
            in atlas: MTLTexture
        ) -> LFloat2 {
            let bundleSize = bundle.texture.simdSize
            let atlasSize = atlas.simdSize
            return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
        }
        
        let uvPacking = AtlasPacking<UVRect>(width: 1.0, height: 1.0)
        for (key, bundle) in textureBundles {
            let uvSize = atlasUVSize(for: bundle, in: atlasTexture)
            let samplePack = UVRect()
            (samplePack.width, samplePack.height) = (uvSize.x, uvSize.y)
            uvPacking.packNextRect(samplePack)
            
            let (left, top, width, height) =
                (samplePack.x, samplePack.y, uvSize.x, uvSize.y)
            
            // Create UV pair matching glyph's texture position
            let topLeft = LFloat2(left, top)
            let bottomLeft = LFloat2(left, top + height)
            let topRight = LFloat2(left + width, top)
            let bottomRight = LFloat2(left + width, top + height)
            
            uvCache[key] = TextureUVCache.Pair(
                u: LFloat4(topRight.x, topLeft.x, bottomLeft.x, bottomRight.x),
                v: LFloat4(topRight.y, topLeft.y, bottomLeft.y, bottomRight.y)
            )
        }
        
        print("Did we pack?")
    }
}
