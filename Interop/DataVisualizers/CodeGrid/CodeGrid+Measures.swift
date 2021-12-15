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
        private let target: CodeGrid
        
        init(targetGrid: CodeGrid) {
            self.target = targetGrid
        }
        
        var lengthX: VectorFloat { sizeNode.lengthX }
        var lengthY: VectorFloat { sizeNode.lengthY }
        var lengthZ: VectorFloat { sizeNode.lengthZ }

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
        
        func setLeading(_ newValue: VectorFloat) {
            xpos = newValue + leadingOffset
        }
        
        func setTrailing(_ newValue: VectorFloat) {
            xpos = newValue - trailingOffset
        }
        
        func setTop(_ newValue: VectorFloat) {
            ypos = newValue - topOffset
        }
        
        func setBottom(_ newValue: VectorFloat) {
            ypos = newValue + bottomOffset
        }
        
        func setFront(_ newValue: VectorFloat) {
            zpos = newValue - frontOffset
        }
        
        func setBack(_ newValue: VectorFloat) {
            zpos = newValue + backOffset
        }
        
        var leadingOffset: VectorFloat { abs(localLeading) }
        var trailingOffset: VectorFloat { abs(localTrailing) }
        var topOffset: VectorFloat { abs(localTop) }
        var bottomOffset: VectorFloat { abs(localBottom) }
        var frontOffset: VectorFloat { abs(localFront) }
        var backOffset: VectorFloat { abs(localBack) }
        
        var boundsMin: SCNVector3 {
            positionNode.convertPosition(
                SCNVector3(localLeading, localBottom, localBack),
                to: positionNode.parent
            )
        }
        
        var boundsMax: SCNVector3 {
            positionNode.convertPosition(
                SCNVector3(localTrailing, localTop, localFront),
                to: positionNode.parent
            )
        }

        var centerPosition: SCNVector3 {
            positionNode.convertPosition(
                SCNVector3(x: localCenterX, y: localCenterY, z: localCenterZ),
                to: positionNode.parent
            )
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
        
        var position: SCNVector3 {
            get { positionNode.position }
            set { positionNode.position = newValue }
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
            position.x = other.measures.centerPosition.x - lengthX / 2.0
            return self
        }
        
        @discardableResult
        func alignedCenterY(_ other: CodeGrid) -> Self {
            position.y = other.measures.centerPosition.y + lengthY / 2.0
            return self
        }
        
        @discardableResult
        func alignedCenterZ(_ other: CodeGrid) -> Self {
            position.z = other.measures.centerPosition.z + lengthZ / 2.0
            return self
        }
    }
}

private extension CodeGrid.Measures {
    private var positionNode: SCNNode { target.rootNode }
    private var sizeNode: SCNNode { target.rootNode }
    
    private var localLeading: VectorFloat {
        get { positionNode.manualBoundingBox.min.x }
    }
    private var localTrailing: VectorFloat {
        get { positionNode.manualBoundingBox.max.x }
    }
    private var localTop: VectorFloat {
        get { positionNode.manualBoundingBox.max.y }
    }
    private var localBottom: VectorFloat {
        get { positionNode.manualBoundingBox.min.y }
    }
    private var localFront: VectorFloat {
        get { positionNode.manualBoundingBox.max.z }
    }
    private var localBack: VectorFloat {
        get { positionNode.manualBoundingBox.min.z }
    }
    
    private var localCenterX: VectorFloat {
        get { localLeading + (lengthX / 2.0) }
    }
    private var localCenterY: VectorFloat {
        get { localTop - (lengthY / 2.0) }
    }
    private var localCenterZ: VectorFloat {
        get { localFront - (lengthZ / 2.0) }
    }
}


extension CodeGrid.Measures {
    var dumpstats: String {
"""
--\(target.id)
nodePosition:     \(positionNode.position)
size:             \(SCNVector3(lengthX, lengthY, lengthZ))
boundsMin:        \(boundsMin)
boundsMax:        \(boundsMax)
boundsCenter:     \(centerPosition)
(leading, top, back):            \(SCNVector3(leading, top, back))
(trailing, bottom, front):       \(SCNVector3(trailing, bottom, front))
local-(leading, top, back):      \(SCNVector3(localLeading, localTop, localBack))
local-(trailing, bottom, front): \(SCNVector3(localTrailing, localBottom, localFront))
offst-(leading, top, back):      \(SCNVector3(leadingOffset, topOffset, backOffset))
offst-(trailing, bottom, front): \(SCNVector3(trailingOffset, bottomOffset, frontOffset))--
"""
    }
}
