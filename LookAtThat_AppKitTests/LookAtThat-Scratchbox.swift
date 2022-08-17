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
    
    func testRects() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw CoreError.noMetalDevice
        }
        
        let view = CustomMTKView(frame: .zero, device: device)
        let link = try MetalLink(view: view)
        let atlas = MetalLinkAtlas(link)
        
        let atlasPacking = AtlasPacking(width: 1000, height: 1000)
        var glphs = [MetalLinkGlyphNode]()
        var rects = [AtlasPacking.VertexRect]()
        
        let testWidth = 100
        let testHeight = 100
        let testLength = 10
        for _ in (0..<testLength) {
            for _ in (0..<testLength) {
                let rect = AtlasPacking.VertexRect()
                rect.width = testWidth
                rect.height = testHeight
                rects.append(rect)
            }
        }
        
        for rect in rects {
            atlasPacking.packNextRect(rect)
        }
        
        var expectedY = 0
        for (index, rect) in rects.striding(by: testLength).enumerated() {
            expectedY = index * testHeight
            XCTAssertEqual(rect.y, expectedY)
        }
        
        print("ya packed son")
    }
}

// With thanks to:
// https://www.david-colson.com/2020/03/10/exploring-rect-packing.html
//
class AtlasPacking {
    class VertexRect {
        var x: Int = 0
        var y: Int = 0
        var width: Int = 0
        var height: Int = 0
        var wasPacked = false
    }
    
    class UVRect {
        var left: Float = 0
        var top: Float = 0
        var width: Float = 0
        var height: Float = 0
        var wasPacked = false
    }
    
    let canvasWidth: Int
    let canvasHeight: Int
    
    private var currentX = 0
    private var currentY = 0
    private var largestHeightThisRow = 0
    
    init(
        width: Int = 700,
        height: Int = 700
    ) {
        self.canvasWidth = width
        self.canvasHeight = height
    }
    
    func packNextRect(_ rect: VertexRect) {
        // If this rectangle will go past the width of the image
        // Then loop around to next row, using the largest height from the previous row
        if (currentX + rect.width) > canvasWidth {
            currentY += largestHeightThisRow
            currentX = 0
            largestHeightThisRow = 0
        }
        
        // If we go off the bottom edge of the image, then we've failed
        if (currentY + rect.height) > canvasHeight {
            print("No placement for \(rect)")
            return
        }
        
        // This is the position of the rectangle
        rect.x = currentX
        rect.y = currentY
        
        // Move along to the next spot in the row
        currentX += rect.width
        
        // Just saving the largest height in the new row
        if rect.height > largestHeightThisRow {
            largestHeightThisRow = rect.height
        }
        
        // Success!
        rect.wasPacked = true;
    }
}
