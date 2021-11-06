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

class WorldGridEditor {
    private lazy var cache = WorldGrid()
    
    init() {
        let bigBangRow = [CodeGrid]()
        let bigBangPlane = [bigBangRow]
        cache.append(bigBangPlane)
    }
    
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
    
    @discardableResult
    func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        switch style {
        case .trailingFromLastGrid(let codeGrid):
            updateRow(z: planeCount, y: lastPlaneRowCount) { row in
                let lastDimensions = lastGridDimensions
                
                row.append(codeGrid)
                
                codeGrid.rootNode.position = lastDimensions.position.translated(
                    dX: lastDimensions.size.lengthX + 8.0
                )
            }

        case .inNextRow(let codeGrid):
            updatePlane(z: lastPlaneRowCount) { plane in
                let lastDimensions = lastGridDimensions
                
                var newRow = WorldGridRow()
                newRow.append(codeGrid)
                plane.append(newRow)
                
                let lastRow = plane.last ?? []
                let maxRowHeight = lastRow.reduce(into: VectorFloat(0.0)) { height, grid in
                    height = max(height, grid.rootNode.lengthY)
                }
                let finalY = maxRowHeight + 16.0
                
                codeGrid.rootNode.position = SCNVector3(
                    x: 0.0,
                    y: finalY,
                    z: lastDimensions.position.z
                )
                
            }
        case .inNextPlane(let codeGrid):
            updateWorldGlobal { world in
                let lastDimensions = lastGridDimensions
                
                var newPlane = WorldGridPlane()
                var newRow = WorldGridRow()
                newRow.append(codeGrid)
                newPlane.append(newRow)
                world.append(newPlane)
                
                codeGrid.rootNode.position = SCNVector3(
                    x: 0,
                    y: 0,
                    z: lastDimensions.position.z + 24.0
                )
                
            }
            
        }
        return self
    }
}

extension WorldGridEditor {
    func updateWorldGlobal(
        _ operation: (inout WorldGrid) -> Void
    ) {
        operation(&cache)
    }
    
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
    var lastRowCount: Int {
        var count: Int = 0
        updateRow(z: planeCount, y: lastPlaneRowCount) {
            count = $0.count
        }
        return count
    }
    
    var lastPlaneRowCount: Int {
        var count: Int = 0
        updatePlane(z: planeCount) {
            count = $0.count
        }
        return count
    }
    
    var planeCount: Int {
        var count: Int = 0
        updateWorldGlobal {
            count = $0.count
        }
        return count
    }
    
    func gridAt(
        z: Int,
        y: Int,
        x: Int,
        _ operation: (CodeGrid) -> Void
    ) {
        updateRow(z: z, y: y) { row in
            guard row.indices.contains(x) else {
                print("invalid gridAt position: \((x, y, z))")
                return
            }
            let grid = row[x]
            operation(grid)
        }
    }
    
    var lastGridDimensions: (
        position: SCNVector3,
        size: (lengthX: VectorFloat, lengthY: VectorFloat, lengthZ: VectorFloat)
    ) {
        var lastKnownGrid: CodeGrid?
        gridAt(z: planeCount - 1, y: lastPlaneRowCount - 1, x: lastRowCount - 1) {
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
