//
//  CodeGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/1/21.
//

import Foundation
import SceneKit

class CodeGridFocus {
    
    var rootGrid: CodeGrid
    
    var bimap: BiMap<SCNNode, Int> = BiMap()
    lazy var constraint = makeConstraint()
    
    init(rootGrid: CodeGrid) {
        self.rootGrid = rootGrid
    }
    
    func depth(_ node: SCNNode) -> CGFloat {
        CGFloat(bimap[node] ?? 0)
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        bimap[grid.rootNode] = nil
        grid.rootNode.removeFromParentNode()
        grid.rootNode.constraints?.removeAll(where: { $0 === constraint })
    }

    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        grid.rootNode.position = SCNVector3Zero
        grid.rootNode.addConstraint(constraint)
        bimap[grid.rootNode] = depth
        
        rootGrid.rootNode.addChildNode(grid.rootNode)
        
        let newBounds = bimap.keysToValues.keys.reduce(into: BoundsComputing()) { result, grid in
            result.consumeBounds(grid.manualBoundingBox)
        }
        newBounds.minZ = 0
        newBounds.maxZ = 25.cg * depth.cg
        rootGrid.resizeGridAsBox(bounds: newBounds.bounds)
    }
    
    func makeConstraint() -> SCNTransformConstraint{
        SCNTransformConstraint.positionConstraint(inWorldSpace: true) { node, position in
            return self.rootGrid.rootNode.position.translated(
                dZ: self.depth(node) * -25.0
            )
//            return SCNVector3(x: position.x, y: position.y, z: self.depth(node) * -25.0)
        }
    }
}
