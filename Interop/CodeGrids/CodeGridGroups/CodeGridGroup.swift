//
//  CodeGridGroup.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/6/22.
//

import Foundation
import MetalLink
import MetalLinkHeaders
import BitHandling

class CodeGridGroup {
    
    let globalRootGrid: CodeGrid
    var controller = LinearConstraintController()
    
    var childGrids = [CodeGrid]()
    var childGroups = [CodeGridGroup]()
    
    var editor = WorldGridEditor()
    var snapping: WorldGridSnapping { editor.snapping }
    
    init(globalRootGrid: CodeGrid) {
        self.globalRootGrid = globalRootGrid
    }
    
    var lastRowTallestGrid: CodeGrid? {
        get { snapping.gridReg2 }
        set { snapping.gridReg2 = newValue }
    }
    
    var lastRowStartingGrid: CodeGrid? {
        get { snapping.gridReg1 }
        set { snapping.gridReg1 = newValue }
    }
    
    var nextRowStartY: Float {
        lastRowTallestGrid.map { $0.bottom - 32.0 }
        ?? 0
    }
    
    var gridsPerColumn = 5
    
    func applyAllConstraints() {
        for childGroup in childGroups {
            childGroup.applyAllConstraints()
        }
        controller.applyConsecutiveConstraints()
    }
    
    func addLines() {
        for childGroup in childGroups {
            
            let line = MetalLinkLine(globalRootGrid.rootNode.link)
            line.setColor(LFloat4(1.0, 0.0, 0.5, 1.0))
            line.appendSegment(about: .zero)
            line.appendSegment(about: childGroup.globalRootGrid.position)
            globalRootGrid.targetNode.add(child: line)
            
            childGroup.addLines()
        }
        controller.applyConsecutiveConstraints()
    }
    
    func addChildGrid(_ grid: CodeGrid) {
        if let lastGrid = childGrids.last {
            controller.add(LinearConstraints.Behind(
                sourceNode: lastGrid.rootNode,
                targetNode: grid.rootNode
            ))
        }
        
        lastRowStartingGrid = lastRowStartingGrid ?? grid
        let isNewGridTaller = (lastRowTallestGrid?.contentSize.y ?? 0) < grid.contentSize.y
        lastRowTallestGrid = isNewGridTaller ? grid : lastRowTallestGrid
        
        childGrids.append(grid)
        globalRootGrid.addChildGrid(grid)
    }
    
    func addChildGroup(_ group: CodeGridGroup) {
        if let lastGroup = childGroups.last {
            controller.add(LinearConstraints.ToTrailingOf(
                sourceNode: lastGroup.globalRootGrid.rootNode,
                targetNode: group.globalRootGrid.rootNode
            ))
        } else {
            controller.add(LiveConstraint(
                sourceNode: MetalLinkNode(),
                targetNode: group.globalRootGrid.rootNode,
                action: { node in
                    LFloat3(
                        x: 0,
                        y: self.nextRowStartY,
                        z: -128
                    )
                }
            ))
        }
        childGroups.append(group)
        globalRootGrid.addChildGrid(group.globalRootGrid)
    }
    
    func isSiblingOfGroup(_ otherGroup: CodeGridGroup) -> Bool {
        if let myPath = globalRootGrid.sourcePath,
            let otherPath = otherGroup.globalRootGrid.sourcePath {
            let isSibling = myPath.isSiblingOf(otherPath)
//            if isSibling { print("\(myPath) is sibling of \(otherPath)") }
            return isSibling
        } else {
            print("<!!! you broke it! \(self) ;;;; \(otherGroup)")
            return false
        }
    }
}

// MARK: Simple layout helpers
// Assumes first grid is initial layout target.
// No, I haven't made constraints yet. Ew.

struct WordGraphLayout {
    func doIt(
        controller: DictionaryController
    ) {
        controller.dictionary.graph.edges.lazy
            .compactMap { edge -> (WordNode, WordNode, WordGraph.Edge)? in
                guard let origin = controller.nodeMap[edge.originID],
                      let destination = controller.nodeMap[edge.destinationID]
                else {
                    return nil
                }
                return (origin, destination, edge)
            }
            .forEach { source, destination, edge in
                //                print(edge.weight)
            }
    }
}

struct ChatLayout {
    func fruchtermanReingold(
        nodes: [WordNode],
        graph: WordGraph,
        width: Float,
        height: Float,
        depth: Float,
        k: Float,
        maxIterations: Int
    ) {
        
        let repulsiveForce: (Float) -> Float = { distance in
            k * k / distance
        }
        
        let attractiveForce: (Float) -> Float = { distance in
            distance * distance / k
        }
        
        print("--- Starting FR iterations")
        for iteration in 0..<maxIterations {
            print("---> Iteration \(iteration)")
            
            for node in nodes {
                var displacement = LFloat3.zero
                
                for otherNode in nodes {
                    if node === otherNode {
                        continue
                    }
                    
                    let direction = otherNode.position - node.position
                    let distance = direction.magnitude
                    
                    // Compute repulsive force
                    let repulsiveMagnitude = repulsiveForce(distance)
                    displacement -= direction.normalized * repulsiveMagnitude
                    
                    // Compute attractive force
                    if let edge = graph.edge(from: otherNode.sourceWord, to: node.sourceWord) {
                        let attractiveMagnitude = attractiveForce(distance) * edge.weight
                        displacement += direction.normalized * attractiveMagnitude
                    }
                }
                
                let newPosition = node.position + displacement
                node.position = LFloat3(
                    x: max(0, min(width, newPosition.x)),
                    y: max(0, min(height, newPosition.y)),
                    z: max(0, min(depth, newPosition.z))
                )
            }
        }
    }
}

protocol LayoutTarget {
    var layoutNode: MetalLinkNode { get }
    var grids: [MetalLinkNode] { get }
}

extension LayoutTarget {
    var grids: [MetalLinkNode] {
        layoutNode.children.compactMap {
           $0 as? GlyphCollection
        }
    }
}

extension CodeGrid: LayoutTarget {
    var layoutNode: MetalLinkNode { rootNode }
}

extension MetalLinkNode: LayoutTarget {
    var layoutNode: MetalLinkNode { self }
}

struct CircleLayout {
    let radius: Float
    func layout(targets: [LayoutTarget]) {
        let total = targets.count
        for (index, target) in targets.enumerated() {
            let angle = 2 * Float.pi * Float(index) / Float(total)
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            target.layoutNode.setTop(y)
            target.layoutNode.setLeading(x)
        }
    }
}

struct DepthLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -256.float
    
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
    
    func layoutGrids2(
        _ centerX: Float,
        _ centerY: Float,
        _ centerZ: Float,
        _ wordNodes: [WordNode],
        _ parent: CodeGrid
    ) {
        var lastTarget: LayoutTarget?
        
        for currentTarget in wordNodes {
            if let lastTarget {
                let final = lastTarget.layoutNode.position.translated(dZ: zGap)
                currentTarget.position = final
            } else {
                let final = LFloat3(x: centerX, y: centerY, z: centerZ)
                currentTarget.position = final
            }
            lastTarget = currentTarget
        }
    }
}

struct HorizontalLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = 0.float
    
    func layoutGrids(
        _ targets: [LayoutTarget]
    ) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.top)
                    .setLeading(lastTarget.layoutNode.trailing + xGap)
                    .setFront(lastTarget.layoutNode.front + zGap)
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
