//
//  CodeGrid+Measures.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import SceneKit

// MARK: -- Measuring and layout

protocol Measures: AnyObject {
    var nodeId: BoundsKey { get }
    var position: LFloat3 { get set }
    var worldPosition: LFloat3 { get set }
    
    var bounds: Bounds { get }
    
    var lengthX: Float { get }
    var lengthY: Float { get }
    var lengthZ: Float { get }
    
    var parent: MetalLinkNode? { get set }
    func convertPosition(_ position: LFloat3, to: MetalLinkNode?) -> LFloat3
    func enumerateChildren(_ action: (MetalLinkNode) -> Void)
}

extension Measures {
    var xpos: VectorFloat {
        get { position.x }
        set { position.x = newValue }
    }
    
    var ypos: VectorFloat {
        get { position.y }
        set { position.y = newValue }
    }
    
    var zpos: VectorFloat {
        get { position.z }
        set { position.z = newValue }
    }
}

// MARK: - Bounds

extension Measures {    
    var parentSpaceBoundsMin: LFloat3 {
        convertPosition(
            LFloat3(localLeading, localBottom, localBack),
            to: parent
        )
    }
    
    var parentSpaceBoundsMax: LFloat3 {
        convertPosition(
            LFloat3(localTrailing, localTop, localFront),
            to: parent
        )
    }
    
    var boundsWidth: Float { BoundsWidth(bounds) }
    var boundsHeight: Float { BoundsHeight(bounds) }
    var boundsLength: Float { BoundsLength(bounds) }
    
    var leading: VectorFloat { bounds.min.x }
    var trailing: VectorFloat { bounds.max.x }
    var top: VectorFloat { parentSpaceBoundsMax.y }
    var bottom: VectorFloat { parentSpaceBoundsMin.y }
    var front: VectorFloat { parentSpaceBoundsMax.z }
    var back: VectorFloat { parentSpaceBoundsMin.z }
    
    var leadingOffset: VectorFloat { abs(boundsCenterPosition.x - boundsWidth / 2.0) }
    var trailingOffset: VectorFloat { abs(boundsCenterPosition.x + boundsWidth / 2.0) }
    var topOffset: VectorFloat { abs(boundsCenterPosition.y - boundsHeight / 2.0) }
    var bottomOffset: VectorFloat { abs(boundsCenterPosition.y + boundsHeight / 2.0) }
    var frontOffset: VectorFloat { abs(localFront) }
    var backOffset: VectorFloat { abs(localBack) }
    
    var boundsCenterWidth: VectorFloat { boundsWidth / 2.0 + bounds.min.x }
    var boundsCenterHeight: VectorFloat { boundsHeight / 2.0 + bounds.min.y }
    var boundsCenterLength: VectorFloat { boundsLength / 2.0 + bounds.min.z }
    
    var boundsCenterPosition: LFloat3 {
        let vector = LFloat3(
            x: boundsCenterWidth,
            y: boundsCenterHeight,
            z: boundsCenterLength
        )
        return vector
    }
}

extension Measures {
    var localLeading: VectorFloat { bounds.min.x }
    
    var localTrailing: VectorFloat { bounds.max.x }
    
    var localTop: VectorFloat { bounds.max.y }
    
    var localBottom: VectorFloat { bounds.min.y }
    
    var localFront: VectorFloat { bounds.max.z }
    
    var localBack: VectorFloat { bounds.min.z }
}

extension Measures {
    @discardableResult
    func setLeading(_ newValue: VectorFloat) -> Self {
        xpos = newValue + lengthX / 2.0
//        xpos = newValue
        return self
    }
    
    @discardableResult
    func setTrailing(_ newValue: VectorFloat) -> Self{
        xpos = newValue - leadingOffset
        return self
    }
    
    @discardableResult
    func setTop(_ newValue: VectorFloat) -> Self {
        ypos = newValue - topOffset
        return self
    }
    
    @discardableResult
    func setBottom(_ newValue: VectorFloat) -> Self {
        ypos = newValue + bottomOffset
        return self
    }
    
    @discardableResult
    func setFront(_ newValue: VectorFloat) -> Self {
        zpos = newValue - frontOffset
        return self
    }
    
    @discardableResult
    func setBack(_ newValue: VectorFloat) -> Self {
        zpos = newValue + frontOffset
        return self
    }
}

extension Measures {
    var boundsCacheKey: BoundsKey { nodeId }
    
    func computeBoundingBox() -> Bounds {
        let computing = BoundsComputing()
        
        enumerateChildren { childNode in
            var safeBox = childNode.bounds
            safeBox.min = convertPosition(safeBox.min, to: parent)
            safeBox.max = convertPosition(safeBox.max, to: parent)
            computing.consumeBounds(safeBox)
        }
        
        //        print("computing: \(computing.bounds)")
        if let sizable = self as? ContentSizing {
            let size = sizable.size
            let offset = sizable.offset
            let min = LFloat3(position.x + offset.x,
                              position.y + offset.y - size.y,
                              position.z + offset.z)
            let max = LFloat3(position.x + offset.x + size.x,
                              position.y + offset.y,
                              position.z + offset.z + size.z)
            //            print("min", min, "max", max)
            computing.consumeBounds((
                min: convertPosition(min, to: parent),
                max: convertPosition(max, to: parent)
            ))
        }
        
        return computing.bounds
    }
}

extension Measures {
    //        size:                            \(SCNVector3(lengthX, lengthY, lengthZ))
    //        boundsCenter:                    \(centerPosition)
    var dumpstats: String {
        """
        ComputedBoundsWidth:             \(boundsWidth)
        ComputedBoundsHeight:            \(boundsHeight)
        ComputedBoundsLength:            \(boundsLength)
        nodePosition:                    \(position)

        boundsMin:                       \(parentSpaceBoundsMin)
        boundsMax:                       \(parentSpaceBoundsMax)

        ComputedBoundsCenter:            \(boundsCenterPosition)
        (leading, top, back):            \(SCNVector3(leading, top, back))
        (trailing, bottom, front):       \(SCNVector3(trailing, bottom, front))
        local-(leading, top, back):      \(SCNVector3(localLeading, localTop, localBack))
        local-(trailing, bottom, front): \(SCNVector3(localTrailing, localBottom, localFront))
        offst-(leading, top, back):      \(SCNVector3(leadingOffset, topOffset, backOffset))
        offst-(trailing, bottom, front): \(SCNVector3(trailingOffset, bottomOffset, frontOffset))
        --
        """
    }
}
