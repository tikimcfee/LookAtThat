//
//  WorldGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/6/21.
//

import Foundation
import SceneKit

typealias WorldGrid = [[[CodeGrid]]]
typealias WorldGridPlane = [[CodeGrid]]
typealias WorldGridRow = [CodeGrid]

enum AddStyle {
    case trailingFromLastGrid(CodeGrid)
    case inNextRow(CodeGrid)
    case inNextPlane(CodeGrid)
    var grid: CodeGrid {
        switch self {
        case .trailingFromLastGrid(let codeGrid):
            return codeGrid
        case .inNextRow(let codeGrid):
            return codeGrid
        case .inNextPlane(let codeGrid):
            return codeGrid
        }
    }
}

class WorldGridEditor {
    private var cache = WorldGrid()
    
    var focusPosition: FocusPosition = (0, 0, 0)
    var lastFocusedGrid: CodeGrid?
    
    init() {
        let bigBangRow = [CodeGrid]()
        let bigBangPlane = [bigBangRow]
        cache.append(bigBangPlane)
    }
    
    @discardableResult
    func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        switch style {
        case .trailingFromLastGrid(let codeGrid):
            updateRow(z: planeCount - 1, y: lastPlaneRowCount - 1) { row in
                let lastDimensions = lastGridDimensions
                let isFirst = row.isEmpty
                row.append(codeGrid)
                
                codeGrid.rootNode.position = lastDimensions.position.translated(
                    dX: lastDimensions.size.lengthX + (isFirst ? 0 : 8.0)
                )
            }

        case .inNextRow(let codeGrid):
            updatePlane(z: planeCount - 1) { plane in
                let lastDimensions = lastGridDimensions
                
                var newRow = WorldGridRow()
                newRow.append(codeGrid)
                plane.append(newRow)
                
                let lastRow = plane.last ?? []
                let maxRowHeight = lastRow.reduce(into: VectorFloat(0.0)) { height, grid in
                    height = max(height, grid.rootNode.lengthY)
                }
                let finalY = lastDimensions.position.y
                    - maxRowHeight
                    - 16.0
                
                codeGrid.rootNode.position = SCNVector3(
                    x: 0.0,
                    y: finalY,
                    z: lastDimensions.position.z
                )
                
            }
            
        case .inNextPlane(let codeGrid):
            let lastDimensions = lastGridDimensions
            
            var newPlane = WorldGridPlane()
            var newRow = WorldGridRow()
            newRow.append(codeGrid)
            newPlane.append(newRow)
            cache.append(newPlane)
            
            codeGrid.rootNode.position = SCNVector3(
                x: 0.0,
                y: 0.0,
                z: lastDimensions.position.z - 256.0
            )
            
        }
        return self
    }
}

extension WorldGridEditor {
    func updatePlane(
        z: Int,
        _ operation: (inout WorldGridPlane) -> Void
    ) {
        guard cache.indices.contains(z) else {
            print("invalid plane position: \(z)")
            return
        }
        
        var plane = cache[z]
        operation(&plane)
        cache[z] = plane
    }
    
    func updateRow(
        z: Int,
        y: Int,
        _ operation: (inout WorldGridRow) -> Void
    ) {
        updatePlane(z: z) { plane in
            guard plane.indices.contains(y) else {
                print("invalid row position: \(y)")
                return
            }
            
            var row = plane[y]
            operation(&row)
            plane[y] = row
        }
    }
}

extension WorldGridEditor {
    func countGridsInRow(_ z: Int, _ y: Int) -> Int {
        guard cache.indices.contains(z),
              cache[z].indices.contains(y)
        else { return 0 }
        return cache[z][y].count
    }
    
    func countRowsInPlane(_ z: Int) -> Int {
        guard cache.indices.contains(z)
        else { return 0 }
        return cache[z].count
    }
    
    func countPlanes() -> Int {
        cache.count
    }
    
    func readPlaneAt(z: Int, _ operation: (WorldGridPlane) -> Void) {
        guard cache.indices.contains(z)
        else { return }
        operation(cache[z])
    }
    
    func readRowAt(z: Int, y: Int, _ operation: (WorldGridRow) -> Void) {
        guard cache.indices.contains(z),
              cache[z].indices.contains(y)
        else { return }
        operation(cache[z][y])
    }
    
    func readGridAt(z: Int, y: Int, x: Int, _ operation: (CodeGrid) -> Void) {
        guard cache.indices.contains(z),
              cache[z].indices.contains(y),
              cache[z][y].indices.contains(z)
        else { return }
        operation(cache[z][y][x])
    }
    
    var lastGridDimensions: (
        position: SCNVector3,
        size: (lengthX: VectorFloat, lengthY: VectorFloat, lengthZ: VectorFloat)
    ) {
        var lastKnownGrid: CodeGrid?
        gridAt(
            z: max(0, planeCount - 1),
            y: max(0, lastPlaneRowCount - 1),
            x: max(0, lastRowGridCount - 1)
        ) {
            lastKnownGrid = $0
        }
        return (
            lastKnownGrid?.rootNode.position ?? SCNVector3Zero,
            (
                lastKnownGrid?.backgroundGeometryNode.lengthX ?? 0.0,
                lastKnownGrid?.backgroundGeometryNode.lengthX ?? 0.0,
                lastKnownGrid?.backgroundGeometryNode.lengthX ?? 0.0
            )
        )
    }
}
