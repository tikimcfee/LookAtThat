//
//  LookAtThat-Scratchbox.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 8/16/22.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import Foundation
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
        
        let uvCache = TextureUVCache()
        let textureBundles: [(GlyphCacheKey, MetalLinkGlyphTextureCache.Bundle)] =
            MetalLinkAtlas.sampleAtlasGlyphs.lazy
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
