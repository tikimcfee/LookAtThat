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
        private var sizeNode: SCNNode { target.backgroundGeometryNode }
        
        var lengthX: VectorFloat { sizeNode.lengthX }
        var lengthY: VectorFloat { sizeNode.lengthY }
        var lengthZ: VectorFloat { sizeNode.lengthZ }
        
        var centerX: VectorFloat {
            get { leading + (lengthX / 2.0) }
        }
        var centerY: VectorFloat {
            get { top - (lengthY / 2.0) }
        }
        var centerZ: VectorFloat {
            get { front - lengthZ / 2.0 }
        }
        var centerPosition: SCNVector3 {
            get { SCNVector3(x: centerX, y: centerY, z: centerZ) }
        }
        
        var top: VectorFloat {
            get { positionNode.position.y }
            set { positionNode.position.y = newValue }
        }
        var bottom: VectorFloat { top - lengthY }
        
        var leading: VectorFloat {
            get { positionNode.position.x }
            set { positionNode.position.x = newValue }
        }
        var trailing: VectorFloat { leading + lengthX }
        
        var front: VectorFloat {
            get { positionNode.position.z }
            set { positionNode.position.z = newValue }
        }
        var back: VectorFloat { front + (lengthZ / 2.0) }
        
        var position: SCNVector3 {
            get { positionNode.position }
            set { positionNode.position = newValue }
        }
        
        @discardableResult
        func alignedToLeadingOf(_ other: CodeGrid, _ pad: VectorFloat = 4.0) -> Self {
            leading = other.measures.leading + pad
            return self
        }
        
        @discardableResult
        func alignedToTrailingOf(_ other: CodeGrid, _ pad: VectorFloat = 4.0) -> Self {
            leading = other.measures.trailing + pad
            return self
        }
        
        @discardableResult
        func alignedToTopOf(_ other: CodeGrid, _ pad: VectorFloat = 4.0) -> Self {
            top = other.measures.top + pad
            return self
        }
        
        @discardableResult
        func alignedToBottomOf(_ other: CodeGrid, _ pad: VectorFloat = 4.0) -> Self {
            top = other.measures.bottom + pad
            return self
        }
        
        @discardableResult
        func alignedCenterX(_ other: CodeGrid) -> Self {
            leading = other.measures.centerX - centerX
            return self
        }
        
        @discardableResult
        func alignedCenterY(_ other: CodeGrid) -> Self {
            top = other.measures.centerY - centerY
            return self
        }
        
        @discardableResult
        func alignedCenterZ(_ other: CodeGrid) -> Self {
            top = other.measures.bottom
            return self
        }
    }
}
