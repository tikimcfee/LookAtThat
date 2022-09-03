//
//  CodeGrid+Measures.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import SceneKit

// MARK: -- Measuring and layout
extension CodeGrid {
    class Measures {
        private let target: MetalLinkNode
        
        private var positionNode: MetalLinkNode { target }
        
        init(target: MetalLinkNode) {
            self.target = target
        }
        
        var xpos: VectorFloat {
            get { positionNode.position.x }
            set { positionNode.position.x = newValue }
        }
        
        var ypos: VectorFloat {
            get { positionNode.position.y }
            set { positionNode.position.y = newValue }
        }
        
        var zpos: VectorFloat {
            get { positionNode.position.z }
            set { positionNode.position.z = newValue }
        }
        
        var position: LFloat3 {
            get { positionNode.position }
            set { positionNode.position = newValue }
        }
        
        var worldPosition: LFloat3 {
            get { positionNode.worldPosition }
            set { positionNode.worldPosition = newValue }
        }
        
        var lengthX: VectorFloat { scaledLengthX }
        var lengthY: VectorFloat { scaledLengthY }
        var lengthZ: VectorFloat { scaledLengthZ }
        
        var leadingOffset: VectorFloat { abs(scaledLocalLeading) }
        var trailingOffset: VectorFloat { abs(scaledLocalTrailing) }
        var topOffset: VectorFloat { abs(scaledLocalTop) }
        var bottomOffset: VectorFloat { abs(scaledLocalBottom) }
        var frontOffset: VectorFloat { abs(scaledLocalFront) }
        var backOffset: VectorFloat { abs(scaledLocalBack) }
        
        var boundsMin: LFloat3 {
            positionNode.convertPositionToParent(
                LFloat3(localLeading, localBottom, localBack)
            )
        }
        
        var boundsMax: LFloat3 {
            positionNode.convertPositionToParent(
                LFloat3(localTrailing, localTop, localFront)
            )
        }
        
        var worldBoundsMin: LFloat3 {
            LFloat3(worldLeading, worldBottom, worldBack)
        }
        
        var worldBoundsMax: LFloat3 {
            LFloat3(worldTrailing, worldTop, worldFront)
        }
        
        var worldBounds: Bounds {
            (min: worldBoundsMin, max: worldBoundsMax)
        }
        
        var centerPosition: LFloat3 {
        LFloat3(x: localCenterX, y: localCenterY, z: localCenterZ)
            // Note: At some point I thought center needed to be converted up.
            // By not converting, though, all my tests pass. I think it's because
            // the position assumptions for SCNNodes and our LinkNodes are different.
            // Could also just be something else was changed in the calculations where
            // this isn't needed anymore. Or maybe even the glyph offset that used to be
            // in GlyphNode were part of it. [center position, offset, parent, convert]
            ///            positionNode.convertPositionToParent(
            ///                LFloat3(x: localCenterX, y: localCenterY, z: localCenterZ)
            ///            )
        }

        var leading: VectorFloat {
            get { boundsMin.x }
        }
        
        var trailing: VectorFloat {
            get { boundsMax.x }
        }
        
        var top: VectorFloat {
            get { boundsMax.y }
        }
        
        var bottom: VectorFloat {
            get { boundsMin.y }
        }
        
        var front: VectorFloat {
            get { boundsMax.z }
        }
        
        var back: VectorFloat {
            get { boundsMin.z }
        }
        
        @discardableResult
        func setLeading(_ newValue: VectorFloat) -> Self {
            xpos = newValue + leadingOffset
            return self
        }
        
        @discardableResult
        func setTrailing(_ newValue: VectorFloat) -> Self{
            xpos = newValue - trailingOffset
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
            zpos = newValue + backOffset
            return self
        }
                
        @discardableResult
        func alignedToLeadingOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            setTrailing(other.measures.leading + pad)
            return self
        }
        
        @discardableResult
        func alignedToTrailingOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            setLeading(other.measures.trailing + pad)
            return self
        }
        
        @discardableResult
        func alignedToTopOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            setBottom(other.measures.top + pad)
            return self
        }
        
        @discardableResult
        func alignedToBottomOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            setTop(other.measures.bottom + pad)
            return self
        }
        
        @discardableResult
        func alignedCenterX(_ other: CodeGrid) -> Self {
            setLeading(other.measures.leading - scaledLengthX / 2.0 + other.measures.scaledLengthX / 2.0)
            return self
        }
        
        @discardableResult
        func alignedCenterY(_ other: CodeGrid) -> Self {
            setTop(other.measures.top + scaledLengthY / 2.0 - other.measures.scaledLengthY / 2.0)
            return self
        }
        
        @discardableResult
        func alignedCenterZ(_ other: CodeGrid) -> Self {
            setBack(other.measures.back - scaledLengthZ / 2.0 + other.measures.scaledLengthZ / 2.0)
            return self
        }
    }
}

private extension CodeGrid.Measures {
    private var scaledLengthX: VectorFloat { positionNode.lengthX * DeviceScale }
    private var scaledLengthY: VectorFloat { positionNode.lengthY * DeviceScale }
    private var scaledLengthZ: VectorFloat { positionNode.lengthZ * DeviceScale }
    
    private var scaledLocalLeading: VectorFloat {
        get { localLeading * DeviceScale }
    }
    private var scaledLocalTrailing: VectorFloat {
        get { localTrailing * DeviceScale }
    }
    private var scaledLocalTop: VectorFloat {
        get { localTop * DeviceScale }
    }
    private var scaledLocalBottom: VectorFloat {
        get { localBottom * DeviceScale }
    }
    private var scaledLocalFront: VectorFloat {
        get { localFront * DeviceScale  }
    }
    private var scaledLocalBack: VectorFloat {
        get { localBack * DeviceScale }
    }
    
    private var scaledLocalCenterX: VectorFloat {
        get { scaledLocalLeading + (scaledLengthX / 2.0) }
    }
    private var scaledLocalCenterY: VectorFloat {
        get { scaledLocalTop - (scaledLengthY / 2.0) }
    }
    private var scaledLocalCenterZ: VectorFloat {
        get { scaledLocalFront - (scaledLengthZ / 2.0) }
    }
}

extension CodeGrid.Measures {
    var worldLeading: VectorFloat {
        get { positionNode.worldPosition.x - positionNode.manualBoundingBox.min.x }
    }
    var worldTrailing: VectorFloat {
        get { positionNode.worldPosition.x + positionNode.manualBoundingBox.max.x }
    }
    var worldTop: VectorFloat {
        get { positionNode.worldPosition.y + positionNode.manualBoundingBox.max.y }
    }
    var worldBottom: VectorFloat {
        get { positionNode.worldPosition.y - positionNode.manualBoundingBox.min.y }
    }
    var worldFront: VectorFloat {
        get { positionNode.worldPosition.z + positionNode.manualBoundingBox.max.z }
    }
    var worldBack: VectorFloat {
        get { positionNode.worldPosition.z - positionNode.manualBoundingBox.min.z }
    }
    
    var localLeading: VectorFloat {
        get { positionNode.manualBoundingBox.min.x }
    }
    var localTrailing: VectorFloat {
        get { positionNode.manualBoundingBox.max.x }
    }
    var localTop: VectorFloat {
        get { positionNode.manualBoundingBox.max.y }
    }
    var localBottom: VectorFloat {
        get { positionNode.manualBoundingBox.min.y }
    }
    var localFront: VectorFloat {
        get { positionNode.manualBoundingBox.max.z }
    }
    var localBack: VectorFloat {
        get { positionNode.manualBoundingBox.min.z }
    }
    
    var localCenterX: VectorFloat {
        get { localLeading + (positionNode.lengthX / 2.0) }
    }
    var localCenterY: VectorFloat {
        get { localTop - (positionNode.lengthY / 2.0) }
    }
    var localCenterZ: VectorFloat {
        get { localFront - (positionNode.lengthZ / 2.0) }
    }
}


extension CodeGrid.Measures {
    var dumpstats: String {
"""
-- \(target.nodeId)
ComputedBoundsWidth:             \(positionNode.boundsWidth)
ComputedBoundsHeight:            \(positionNode.boundsHeight)
ComputedBoundsLength:            \(positionNode.boundsLength)
nodePosition:                    \(positionNode.position)
size:                            \(SCNVector3(lengthX, lengthY, lengthZ))
boundsMin:                       \(boundsMin)
boundsMax:                       \(boundsMax)
boundsCenter:                    \(centerPosition)
ComputedBoundsCenter:            \(positionNode.boundsCenterPosition)
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
