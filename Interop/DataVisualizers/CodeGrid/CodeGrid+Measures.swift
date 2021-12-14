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
        
        var leading: VectorFloat { boundsMin.x }
        var trailing: VectorFloat { boundsMax.x }
        var top: VectorFloat { boundsMax.y }
        var bottom: VectorFloat { boundsMin.y }
        var front: VectorFloat { boundsMax.z }
        var back: VectorFloat { boundsMin.z }
        
        var position: SCNVector3 {
            get { positionNode.position }
            set { positionNode.position = newValue }
        }
        
        var boundsMin: SCNVector3 {
            positionNode.convertVector(
                SCNVector3(localLeading, localBottom, localBack),
                to: positionNode.parent
            )
        }
        
        var boundsMax: SCNVector3 {
            positionNode.convertVector(
                SCNVector3(localTrailing, localTop, localFront),
                to: positionNode.parent
            )
        }

        var centerPosition: SCNVector3 {
            get {
                positionNode.convertPosition(
                    SCNVector3(x: localCenterX, y: localCenterY, z: localCenterZ),
                    to: positionNode.parent
                )
            }
        }
                
        @discardableResult
        func alignedToLeadingOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            position.x = other.measures.position.x + pad
            return self
        }
        
        @discardableResult
        func alignedToTrailingOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            position.x = other.measures.position.x + other.measures.lengthX + pad
            return self
        }
        
        @discardableResult
        func alignedToTopOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
            position.y = other.measures.position.y + pad
            return self
        }
        
        @discardableResult
        func alignedToBottomOf(_ other: CodeGrid, pad: VectorFloat) -> Self {
//            position.y = other.measures.position.y - other.measures.lengthY - pad
            position.y = other.measures.localBottom - pad
            print("!!! --- TODO - stop using localBottom and use proper offset")
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
nodePosition: \(positionNode.position)
boundsCenter: \(centerPosition)

xmin: \(leading), xmax: \(trailing), lx:\(lengthX)
ymax: \(top), ymin: \(bottom), ly:\(lengthY)
zmax: \(front), zmin: \(back), lz:\(lengthZ)
--
"""
    }
}
