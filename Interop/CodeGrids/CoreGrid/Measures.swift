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
}

extension Measures {
    @discardableResult
    func setLeading(_ newValue: VectorFloat) -> Self {
        let delta = abs(localLeading - newValue)
        xpos += delta
        return self
    }
    
    @discardableResult
    func setTrailing(_ newValue: VectorFloat) -> Self{
        let delta = abs(localTrailing - newValue)
        xpos -= delta
        return self
    }
    
    @discardableResult
    func setTop(_ newValue: VectorFloat) -> Self {
        let delta = abs(localTop - newValue)
        ypos -= delta
        return self
    }
    
    @discardableResult
    func setBottom(_ newValue: VectorFloat) -> Self {
        let delta = abs(localBottom - newValue)
        ypos += delta
        return self
    }
    
    @discardableResult
    func setFront(_ newValue: VectorFloat) -> Self {
        let delta = abs(localFront - newValue)
        zpos -= delta
        return self
    }
    
    @discardableResult
    func setBack(_ newValue: VectorFloat) -> Self {
        let delta = abs(localBack - newValue)
        zpos += delta
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
        
        if hasIntrinsicSize {
            let size = contentSize
            let offset = contentOffset
            let min = LFloat3(position.x + offset.x,
                              position.y + offset.y - size.y,
                              position.z + offset.z)
            let max = LFloat3(position.x + offset.x + size.x,
                              position.y + offset.y,
                              position.z + offset.z + size.z)
            
            computing.consumeBounds((
                min: convertPosition(min, to: parent),
                max: convertPosition(max, to: parent)
            ))
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
