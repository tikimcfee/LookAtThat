//
//  AtlasPacking.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/18/22.
//
//  With thanks to:
//  https://www.david-colson.com/2020/03/10/exploring-rect-packing.html
//

import Foundation

protocol AtlasPackable: AnyObject {
    associatedtype Number: AdditiveArithmetic & Comparable
    var x: Number { get set }
    var y: Number { get set }
    var width: Number { get set }
    var height: Number { get set }
    var wasPacked: Bool { get set }
}

class UVRect: AtlasPackable {
    var x: Float = .zero
    var y: Float = .zero
    var width: Float = .zero
    var height: Float = .zero
    var wasPacked = false
}

class VertexRect: AtlasPackable {
    var x: Int = .zero
    var y: Int = .zero
    var width: Int = .zero
    var height: Int = .zero
    var wasPacked = false
}

class AtlasPacking<T: AtlasPackable> {
    let canvasWidth: T.Number
    let canvasHeight: T.Number
    
    private(set) var currentX: T.Number = .zero
    private(set) var currentY: T.Number = .zero
    private var largestHeightThisRow: T.Number = .zero
    
    init(
        width: T.Number,
        height: T.Number
    ) {
        self.canvasWidth = width
        self.canvasHeight = height
    }
    
    func packNextRect(_ rect: T) {
        // If this rectangle will go past the width of the image
        // Then loop around to next row, using the largest height from the previous row
        if (currentX + rect.width) > canvasWidth {
            currentY += largestHeightThisRow
            currentX = .zero
            largestHeightThisRow = .zero
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
