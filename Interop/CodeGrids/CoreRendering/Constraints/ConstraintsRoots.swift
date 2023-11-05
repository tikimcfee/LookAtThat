//  LookAtThat_AppKit
//
//  Created on 9/17/23.
//  

import SwiftUI
import MetalLink
import MetalLinkHeaders
import MetalLinkResources

protocol BasicConstraint {
    func apply()
}

open class BasicOffsetConstraint: BasicConstraint {
    var sourceNode: MetalLinkNode
    var targetNode: MetalLinkNode
    var offset: LFloat3
    
    init(
        sourceNode: MetalLinkNode,
        targetNode: MetalLinkNode,
        offset: LFloat3 = .zero
    ) {
        self.sourceNode = sourceNode
        self.targetNode = targetNode
        self.offset = offset
    }
    
    open func apply() {
        targetNode.position =
            sourceNode.position.translated(
                dX: offset.x,
                dY: offset.y,
                dZ: offset.z
            );
    }
}

open class LiveConstraint: BasicConstraint {
    var sourceNode: MetalLinkNode
    var targetNode: MetalLinkNode
    let action: (MetalLinkNode) -> LFloat3
    
    init(
        sourceNode: MetalLinkNode,
        targetNode: MetalLinkNode,
        action: @escaping (MetalLinkNode) -> LFloat3
    ) {
        self.sourceNode = sourceNode
        self.targetNode = targetNode
        self.action = action
    }
    
    open func apply() {
        targetNode.position = action(sourceNode)
    }
}

class LinearConstraintController {
    var constraints = [any BasicConstraint]()
    
    func applyConsecutiveConstraints() {
        for constraint in constraints {
            constraint.apply()
        }
    }
    
    func add(_ constraint: any BasicConstraint) {
        constraints.append(constraint)
    }
}

// MARK: - Basic Constraints


struct LinearConstraints {
    private init() { }
    
    class ToTrailingOf: BasicOffsetConstraint {
        static let xOffset: Float = 16.0
        open override func apply() {
            targetNode.setTop(sourceNode.top + offset.y)
            targetNode.setLeading(sourceNode.trailing + Self.xOffset + offset.x)
            targetNode.setFront(sourceNode.front + offset.z)
        }
    }
    
    class ToTrailingOfFront: BasicOffsetConstraint {
        static let xOffset: Float = 16.0
        open override func apply() {
            targetNode.setTop(sourceNode.top + offset.y)
            targetNode.setLeading(sourceNode.trailing + Self.xOffset + offset.x)
            targetNode.setBack(sourceNode.front + offset.z)
        }
    }
    
    class Behind: BasicOffsetConstraint {
        static let depth: Float = -128.0
        open override func apply() {
            targetNode.setTop(sourceNode.top + offset.y)
            targetNode.setLeading(sourceNode.leading + offset.x)
            targetNode.setFront(sourceNode.back + Self.depth + offset.z)
        }
    }
    
    class Underneath: BasicOffsetConstraint {
        static let yOffset: Float = -16.0
        open override func apply() {
            targetNode.setTop(sourceNode.bottom + Self.yOffset + offset.y)
            targetNode.setLeading(sourceNode.leading + offset.x)
            targetNode.setBack(sourceNode.back + offset.z)
        }
    }
}
