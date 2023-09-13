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

// TODO: Make a simple directory container
// Like the old FocusBox but simpler. Keep some of the fancy
// ideas like moving grids around and different layouts. Don't
// need the "shim" anymore.. that was a bit too much anyway.

class DirectoryCalculator {
    let cache = GlobalInstances.gridStore.gridCache
    let snapping = GlobalInstances.gridStore.editor.snapping
    
    var positionDict: [URL: (Float, Float, Float)] = [:]
    let depthSpacingFactor = 4.0.float
    let paddingBetweenLayers = 32.0.float
    let paddingBetweenNodes = 32.0.float
    
    func calculateMaxHeightInLayer(for child: URL) -> Float {
        return 8.0
    }
    
    func traverseTreeSecondPass_Y(root: URL) {
        // Get all children of the root directory
        let children = childrenOfDirectory(at: root)
        
        // Initialize X and Z coordinates
        var x: Float = positionDict[root]?.0 ?? 0.0.float // Start from parent's x-coordinate
        var z: Float = depthOfDirectory(at: root).float * depthSpacingFactor
        
        // Calculate Y coordinate based on the height of its parent directory
        let parentY = positionDict[root]?.1 ?? 0.0.float
        var y: Float = parentY - paddingBetweenLayers
        
        for child in children {
            // Determine size of the child node (file or directory)
            let (width, height) = sizeOfFile(at: child)
            
            if child.isDirectory {
                // If it's a directory, recursively process its children.
                x = positionDict[root]?.0 ?? 0.0.float // Reset x-coordinate back to initial value for each new row (subdirectory)
                positionDict[child] = (x, y - paddingBetweenLayers, z)
                traverseTreeSecondPass(root: child)
                
                // Adjust Z coordinate based on maximum height in this layer before moving on to next sibling at same level.
                z += calculateMaxHeightInLayer(for: child) + paddingBetweenLayers
                
                // Reset Y coordinate after finishing with one directory.
                y -= height + paddingBetweenLayers * 3
            } else {
                // For files, store this node's position and increase X coordinate by file's width + some padding.
                positionDict[child] = (x, y, z)
                x += width + paddingBetweenNodes
            }
        }
    }
    
    func traverseTreeSecondPass(root: URL) {
        // Get all children of the root directory
        let children = childrenOfDirectory(at: root)
        
        // Initialize X and Z coordinates
        var x: Float = 0.0
        var z: Float = depthOfDirectory(at: root).float * depthSpacingFactor
        var y: Float = z
        
        for child in children {
            // Determine size of the child node (file or directory)
            let (width, _) = sizeOfFile(at: child)
            
            // Set Y-coordinate to 0 as we're laying out nodes horizontally.
            let y : Float = 0.0
            
            // Store this node's position
            positionDict[child] = (x, y, z)
            
            // Move X coordinate for next sibling by width of current node + some padding if required
            x += width + paddingBetweenNodes
            
            if child.isDirectory {
                // If it's a directory, recursively process its children
                traverseTreeSecondPass(root: child)
                
                // Adjust Z coordinate based on maximum height in this layer before moving on to next sibling at same level
                z += calculateMaxHeightInLayer(for: child) + paddingBetweenLayers
            }
        }
    }
    
    func depthOfDirectory(at url: URL) -> Int {
        let pathComponents = url.pathComponents
        return pathComponents.count - 1 // subtracting 1 because the root directory itself should not be counted
    }
    
    func getGrid(for child: URL) -> CodeGrid {
        let gridName  = child.lastPathComponent
        return cache.getOrCache(child)
            .withFileName(gridName)
            .withSourcePath(child)
            .applyName()
    }
    
    func sizeOfFile(at child: URL) -> (width: Float, height: Float) {
        let grid = getGrid(for: child)
        return (width: grid.contentSize.x, height: grid.contentSize.y)
    }
    
    func childrenOfDirectory(at url: URL) -> [URL] {
        FileBrowser.recursivePaths(url)
    }
    
    func computeTotalSizeOfDirectory(at url: URL) -> (width: Float, height: Float) {
        var totalHeight: Float = 0.0
        var totalWidth: Float = 0.0
        
        for child in childrenOfDirectory(at: url) {
            if child.isDirectory {
                let (childWidth, childHeight) = computeTotalSizeOfDirectory(at: child)
                totalHeight += childHeight
                totalWidth += childWidth
            } else { // it's a file
                let fileSize = sizeOfFile(at: child)
                totalHeight += fileSize.height
                totalWidth += fileSize.width
            }
        }
        
        return (totalHeight, totalWidth)
    }
}

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
    
    func applyAllConstraints() {
        for childGroup in childGroups {
            childGroup.applyAllConstraints()
        }
        controller.applyConsecutiveConstraints()
    }
    
    func addChildGrid(_ grid: CodeGrid) {
        if let lastGrid = childGrids.last {
            controller.add(LiveConstraint(
                sourceNode: lastGrid.rootNode,
                targetNode: grid.rootNode,
                action: { last in
                    LFloat3(
                        x: last.contentSize.x + 8,
                        y: 0,
                        z: 0
                    )
                }
            ))
        }
        lastRowStartingGrid = lastRowStartingGrid ?? grid
        lastRowTallestGrid = (lastRowTallestGrid?.contentSize.y ?? 0) < grid.contentSize.y ? grid : lastRowTallestGrid
        
        childGrids.append(grid)
        globalRootGrid.addChildGrid(grid)
    }
    
    func addChildGroup(_ group: CodeGridGroup) {
        if let lastGroup = childGroups.last {
            controller.add(LiveConstraint(
                sourceNode: lastGroup.globalRootGrid.rootNode,
                targetNode: group.globalRootGrid.rootNode,
                action: { node in
                    LFloat3(
                        x: node.contentSize.x + 8,
                        y: 0,
                        z: 0
                    )
                }
            ))
        }
        else {
            controller.add(LiveConstraint(
                sourceNode: MetalLinkNode(),
                targetNode: group.globalRootGrid.rootNode,
                action: { node in
                    LFloat3(
                        x: 32,
                        y: self.nextRowStartY,
                        z: -128
                    )
                }
            ))
        }
        childGroups.append(group)
        globalRootGrid.addChildGrid(group.globalRootGrid)
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

struct RadialLayout {
    let magnitude: Float
    
    init(magnitude: Float) {
        self.magnitude = magnitude
    }
    
    func layoutGrids2(
        _ centerX: Float,
        _ centerY: Float,
        _ centerZ: Float,
        _ radius: Float,
        _ wordNodes: [WordNode],
        _ parent: CodeGrid
    ) {
        let numberOfWords = wordNodes.count
        let step = 360.0 / numberOfWords.float
        
        for i in 0..<numberOfWords {
            let angleInDegrees = step * i.float
            let angleInRadians = angleInDegrees * Float.pi / 180
            let x = centerX + radius * cos(angleInRadians)
            //            let y = centerY + radius * -sin(angleInRadians)
            let z = centerZ + radius * -sin(angleInRadians)
            let final = LFloat3(x: x, y: centerY, z: z)
            //            wordNodes[i].layoutNode.position = LFloat3(x: x, y: y, z: centerZ)
            let node = wordNodes[i]
            var xOffset: Float = -node.contentSize.x / 2.0
            for glyph in wordNodes[i].glyphs {
                parent.updateNode(glyph) {
                    $0.modelMatrix.columns.3.x = xOffset + final.x
                    $0.modelMatrix.columns.3.y = final.y
                    $0.modelMatrix.columns.3.z = final.z
                    //                    $0.modelMatrix.translate(vector: vector)
                }
                xOffset += glyph.contentSize.x
            }
        }
    }
    
    // TODO: Doesn't quite work, not taking rotation into account for bounds.. I think
    func layoutGrids(_ nodes: [LayoutTarget]) {
        guard nodes.count > 1 else { return }
        let nodeCount = nodes.count
        
        let twoPi = 2.0 * Float.pi
        let childRadians = twoPi / nodeCount.float
        let childRadianStride = stride(from: 0.0, to: twoPi, by: childRadians)
        
        zip(nodes, childRadianStride).enumerated().forEach { index, gridTuple in
            let (node, radians) = gridTuple
            
            let radialX = (cos(radians) * (magnitude))
            let radialY = 0.float
            let radialZ = (sin(radians) * (magnitude))
            
            node.layoutNode.position = LFloat3.zero.translated(
                dX: radialX,
                dY: radialY,
                dZ: radialZ
            )
            //            node.layoutNode.rotation.y = radians
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
            currentTarget.update {
                if let lastTarget {
                    let final = lastTarget.layoutNode.position.translated(dZ: zGap)
                    $0.position = final
                } else {
                    let final = LFloat3(x: centerX, y: centerY, z: centerZ)
                    $0.position = final
                }
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
