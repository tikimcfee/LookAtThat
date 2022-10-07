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
    func layoutGrids(_ grids: [CodeGrid]) {
        guard grids.count > 1 else { return }
        let gridCount = grids.count
        
        let twoPi = 2.0 * Float.pi
        let childRadians = twoPi / gridCount.float
        let childRadianStride = stride(from: 0.0, to: twoPi, by: childRadians)
        let magnitude = 64.float
        
        zip(grids, childRadianStride).enumerated().forEach { index, gridTuple in
            let (grid, radians) = gridTuple
            
            let radialX = (cos(radians) * (magnitude))
            let radialY = 0.float
            let radialZ = -(sin(radians) * (magnitude))

            grid.position = LFloat3.zero.translated(
                dX: radialX,
                dY: radialY,
                dZ: radialZ
            )
            grid.rotation.y = radians
        }
    }
}

protocol LayoutTarget {
    var node: MetalLinkNode { get }
}

extension CodeGrid: LayoutTarget {
    var node: MetalLinkNode { rootNode }
}

struct DepthLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -128.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.node
                    .setTop(lastTarget.node.top)
                    .setLeading(lastTarget.node.leading)
                    .setFront(lastTarget.node.back + zGap)
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
                currentTarget.node
                    .setTop(lastTarget.node.top)
                    .setLeading(lastTarget.node.trailing + xGap)
                    .setFront(lastTarget.node.front)
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
                currentTarget.node
                    .setTop(lastTarget.node.bottom + yGap)
                    .setLeading(lastTarget.node.leading)
                    .setFront(lastTarget.node.front)
            }
            lastTarget = currentTarget
        }
    }
}
