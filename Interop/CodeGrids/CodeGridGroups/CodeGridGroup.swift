//
//  CodeGridGroup.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/6/22.
//

import Foundation

// TODO: Make a simple directory container
// Like the old FocusBox but simpler. Keep some of the fancy
// ideas like moving grids around and different layouts. Don't
// need the "shim" anymore.. that was a bit too much anyway.
class CodeGridGroup {
    var grids = [CodeGrid]()
    
    func appendGrid(_ grid: CodeGrid) {
        
    }
    
    func prependGrid(_ grid: CodeGrid) {
        
    }
    
    func insertGrid(_ grid: CodeGrid, at position: Int) {
        if grids.indices.contains(position) {
            
        } else {
            
        }
    }
}

// MARK: Simple layout helpers
// Assumes first grid is initial layout target.
// No, I haven't made constraints yet. Ew.

struct RadialLayout {
    func layoutGrids(_ nodes: [LayoutTarget]) {
        guard nodes.count > 1 else { return }
        let nodeCount = nodes.count
        
        let twoPi = 2.0 * Float.pi
        let childRadians = twoPi / nodeCount.float
        let childRadianStride = stride(from: 0.0, to: twoPi, by: childRadians)
        let magnitude = nodes.max(by: { $0.layoutNode.lengthZ < $1.layoutNode.lengthZ })?.layoutNode.lengthZ ?? 64
        
        zip(nodes, childRadianStride).enumerated().forEach { index, gridTuple in
            let (node, radians) = gridTuple
            
            let radialX = (cos(radians) * (magnitude))
            let radialY = 0.float
            let radialZ = -(sin(radians) * (magnitude))

            node.layoutNode.position = LFloat3.zero.translated(
                dX: radialX,
                dY: radialY,
                dZ: radialZ
            )
            node.layoutNode.rotation.y = radians
        }
    }
}

protocol LayoutTarget {
    var layoutNode: MetalLinkNode { get }
}

extension CodeGrid: LayoutTarget {
    var layoutNode: MetalLinkNode { rootNode }
}

extension MetalLinkNode: LayoutTarget {
    var layoutNode: MetalLinkNode { self }
}

struct DepthLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -64.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.top)
                    .setLeading(lastTarget.layoutNode.leading)
                    .setFront(lastTarget.layoutNode.back + zGap)
            }
            lastTarget = currentTarget
        }
    }
}

struct HorizontalLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -128.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.top)
                    .setLeading(lastTarget.layoutNode.trailing + xGap)
                    .setFront(lastTarget.layoutNode.front)
            }
            lastTarget = currentTarget
        }
    }
}

class VerticalLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -128.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.bottom + yGap)
                    .setLeading(lastTarget.layoutNode.leading)
                    .setFront(lastTarget.layoutNode.front)
            }
            lastTarget = currentTarget
        }
    }
}
