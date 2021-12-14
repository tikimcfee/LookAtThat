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
        let target: CodeGrid
        init(targetGrid: CodeGrid) {
            self.target = targetGrid
        }
        
        private var positionNode: SCNNode { target.rootNode }
        private var sizeNode: SCNNode { target.rootNode }
        
        var lengthX: VectorFloat { sizeNode.lengthX }
        var lengthY: VectorFloat { sizeNode.lengthY }
        var lengthZ: VectorFloat { sizeNode.lengthZ }
        
        var leading: VectorFloat {
            get { positionNode.manualBoundingBox.min.x }
        }
        var trailing: VectorFloat {
            get { positionNode.manualBoundingBox.max.x }
        }
        var top: VectorFloat {
            get { positionNode.manualBoundingBox.max.y }
        }
        var bottom: VectorFloat {
            get { positionNode.manualBoundingBox.min.y }
        }
        var front: VectorFloat {
            get { positionNode.manualBoundingBox.max.z }
        }
        var back: VectorFloat {
            get { positionNode.manualBoundingBox.min.z }
        }
        
        private var localCenterX: VectorFloat {
            get { leading + (lengthX / 2.0) }
        }
        private var localCenterY: VectorFloat {
            get { top - (lengthY / 2.0) }
        }
        private var localCenterZ: VectorFloat {
            get { front - (lengthZ / 2.0) }
        }
        
        var centerPosition: SCNVector3 {
            get {
                positionNode.convertPosition(
                    SCNVector3(x: localCenterX, y: localCenterY, z: localCenterZ),
                    to: positionNode.parent
                )
            }
        }
        
        var position: SCNVector3 {
            get { positionNode.position }
            set { positionNode.position = newValue }
        }
        
        private var dump: String {
"""
--\(target.id)
nodePosition: \(positionNode.position)
boundsCenter: \(centerPosition)
(lx:\(lengthX),ly:\(lengthY),lz:\(lengthZ))
--
"""
        }
        
        func dumpit() {
            print(dump)
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
            position.y = other.measures.bottom - pad
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
