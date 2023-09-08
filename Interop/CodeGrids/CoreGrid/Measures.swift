//
//  CodeGrid+Measures.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import SceneKit
import MetalLink

// MARK: -- Measuring and layout

public protocol Measures: AnyObject {
    var nodeId: String { get }
    
    var rectPos: Bounds { get }
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

public extension Measures {
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
public extension Measures {
    var contentHalfWidth: Float { contentSize.x / 2.0 }
    var contentHalfHeight: Float { contentSize.y / 2.0 }
    var contentHalfLength: Float { contentSize.z / 2.0 }
}

// MARK: - Bounds

public extension Measures {
    var boundsWidth: VectorFloat {
        let currentBounds = bounds
        return BoundsWidth(currentBounds)
    }
    var boundsHeight: VectorFloat {
        let currentBounds = bounds
        return BoundsHeight(currentBounds)
    }
    var boundsLength: VectorFloat {
        let currentBounds = bounds
        return BoundsLength(currentBounds)
    }
    
    var boundsCenterWidth: VectorFloat {
        let currentBounds = bounds
        return currentBounds.min.x + BoundsWidth(currentBounds) / 2.0
    }
    var boundsCenterHeight: VectorFloat {
        let currentBounds = bounds
        return currentBounds.min.x + BoundsHeight(currentBounds) / 2.0
    }
    var boundsCenterLength: VectorFloat {
        let currentBounds = bounds
        return currentBounds.min.x + BoundsLength(currentBounds) / 2.0
    }
    
    var boundsCenterPosition: LFloat3 {
        let currentBounds = bounds
        let vector = LFloat3(
            x: currentBounds.min.x + BoundsWidth(currentBounds) / 2.0,
            y: currentBounds.min.y + BoundsHeight(currentBounds) / 2.0,
            z: currentBounds.min.z + BoundsLength(currentBounds) / 2.0
        )
        return vector
    }
}

// MARK: - Named positions

extension Measures {
    var leading: VectorFloat { localLeading }
    var trailing: VectorFloat { localTrailing }
    var top: VectorFloat { localTop }
    var bottom: VectorFloat { localBottom }
    var front: VectorFloat { localFront }
    var back: VectorFloat { localBack }
    
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
//        let delta = abs(leading - newValue)
        let delta = newValue - leading
        xpos += delta
        return self
    }
    
    @discardableResult
    func setTrailing(_ newValue: VectorFloat) -> Self{
//        let delta = abs(trailing - newValue)
//        xpos -= delta
        let delta = newValue - trailing
        xpos += delta
        return self
    }
    
    @discardableResult
    func setTop(_ newValue: VectorFloat) -> Self {
//        let delta = abs(top - newValue)
        let delta = newValue - top
//        ypos -= delta
        ypos += delta
        return self
    }
    
    @discardableResult
    func setBottom(_ newValue: VectorFloat) -> Self {
//        let delta = abs(bottom - newValue)
        let delta = newValue - bottom
        ypos += delta
        return self
    }
    
    @discardableResult
    func setFront(_ newValue: VectorFloat) -> Self {
//        let delta = abs(front - newValue)
        let delta = newValue - front
//        zpos -= delta
        zpos += delta
        return self
    }
    
    @discardableResult
    func setBack(_ newValue: VectorFloat) -> Self {
//        let delta = abs(back - newValue)
        let delta = newValue - back
        zpos += delta
        return self
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
