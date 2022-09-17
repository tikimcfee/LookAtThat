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
    var nodeId: String { get }
    
//    var rectPos: Bounds { get }
    var bounds: Bounds { get }
    var position: LFloat3 { get set }
    var worldPosition: LFloat3 { get set }
    
    var hasIntrinsicSize: Bool { get }
    var contentSize: LFloat3 { get }
    var contentOffset: LFloat3 { get }
    
    var parent: MetalLinkNode? { get set }
    func convertPosition(_ position: LFloat3, to: MetalLinkNode?) -> LFloat3
    func enumerateChildren(_ action: (MetalLinkNode) -> Void)
}

// MARK: - Position

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

// MARK: - Size
extension Measures {
    var halfWidth: Float { contentSize.x / 2.0 }
    var halfHeight: Float { contentSize.y / 2.0 }
    var halfLength: Float { contentSize.z / 2.0 }
}

// MARK: - Bounds

extension Measures {    
    var boundsCenterWidth: VectorFloat { bounds.min.x + halfWidth }
    var boundsCenterHeight: VectorFloat { bounds.min.y + halfHeight }
    var boundsCenterLength: VectorFloat { bounds.min.z + halfLength }
    
    var boundsCenterPosition: LFloat3 {
        let vector = LFloat3(
            x: boundsCenterWidth,
            y: boundsCenterHeight,
            z: boundsCenterLength
        )
        return vector
    }
}

// MARK: - Named positions

extension Measures {
    var localLeading: VectorFloat { bounds.min.x }
    var localTrailing: VectorFloat { bounds.max.x }
    var localTop: VectorFloat { bounds.max.y }
    var localBottom: VectorFloat { bounds.min.y }
    var localFront: VectorFloat { bounds.max.z }
    var localBack: VectorFloat { bounds.min.z }
    
//    var leading: VectorFloat { rectPos.min.x }
//    var trailing: VectorFloat { rectPos.max.x }
//    var top: VectorFloat { rectPos.max.y }
//    var bottom: VectorFloat { rectPos.min.y }
//    var front: VectorFloat { rectPos.max.z }
//    var back: VectorFloat { rectPos.min.z }
    
    var leading: VectorFloat { localLeading }
    var trailing: VectorFloat { localTrailing }
    var top: VectorFloat { localTop }
    var bottom: VectorFloat { localBottom }
    var front: VectorFloat { localFront }
    var back: VectorFloat { localBack }
}

extension Measures {
    @discardableResult
    func setLeading(_ newValue: VectorFloat) -> Self {
        let delta = abs(leading - newValue)
        xpos += delta
        return self
    }
    
    @discardableResult
    func setTrailing(_ newValue: VectorFloat) -> Self{
        let delta = abs(trailing - newValue)
        xpos -= delta
        return self
    }
    
    @discardableResult
    func setTop(_ newValue: VectorFloat) -> Self {
        let delta = abs(top - newValue)
        ypos -= delta
        return self
    }
    
    @discardableResult
    func setBottom(_ newValue: VectorFloat) -> Self {
        let delta = abs(bottom - newValue)
        ypos += delta
        return self
    }
    
    @discardableResult
    func setFront(_ newValue: VectorFloat) -> Self {
        let delta = abs(front - newValue)
        zpos -= delta
        return self
    }
    
    @discardableResult
    func setBack(_ newValue: VectorFloat) -> Self {
        let delta = abs(back - newValue)
        zpos += delta
        return self
    }
}

extension Measures {
    
    
    func computeBoundingBox(convertParent: Bool = true) -> Bounds {
        let computing = BoundsComputing()
        
        enumerateChildren { childNode in
            var safeBox = childNode.bounds
            if convertParent {
                safeBox.min = convertPosition(safeBox.min, to: parent)
                safeBox.max = convertPosition(safeBox.max, to: parent)
            }
            computing.consumeBounds(safeBox)
        }
        
        if hasIntrinsicSize {
            let size = contentSize
            let offset = contentOffset
            var min = LFloat3(position.x + offset.x,
                              position.y + offset.y - size.y,
                              position.z + offset.z)
            var max = LFloat3(position.x + offset.x + size.x,
                              position.y + offset.y,
                              position.z + offset.z + size.z)
            min = convertParent ? convertPosition(min, to: parent) : min
            max = convertParent ? convertPosition(max, to: parent) : max
            computing.consumeBounds((min, max))
        }
        
        return computing.bounds
    }
}

extension Measures {
    var dumpstats: String {
        """
        ContentSizeX:                    \(contentSize.x)
        ContentSizeY:                    \(contentSize.y)
        ContentSizeZ:                    \(contentSize.z)
        
        nodePosition:                    \(position)
        worldPosition:                   \(worldPosition)

        boundsMin:                       \(bounds.min)
        boundsMax:                       \(bounds.max)
        boundsCenter:                    \(boundsCenterPosition)
        --
        """
    }
}
