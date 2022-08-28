//
//  WorldGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/6/21.
//

import Foundation

var default__PlaneSpacing: VectorFloat = 256.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 128.0

typealias WorldGrid = [[[CodeGrid]]]
typealias WorldGridPlane = [[CodeGrid]]
typealias WorldGridRow = [CodeGrid]

class WorldGridEditor {
    private let snapping = WorldGridSnapping()
    var lastFocusedGrid: CodeGrid?
    
    init() {
        
    }
    
    @discardableResult
    func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        guard let lastGrid = lastFocusedGrid else {
            print("Setting first focused grid: \(style)")
            lastFocusedGrid = style.grid
            return self
        }
        
        switch style {
        case .trailingFromLastGrid(let codeGrid):
            addTrailing(codeGrid, to: lastGrid)
            
        case .inNextRow(let codeGrid):
            addInNextRow(codeGrid, from: lastGrid)
            
        case .inNextPlane(let codeGrid):
            addInNextPlane(codeGrid, from: lastGrid)
        }
        
        return self
    }
}

extension WorldGridEditor {
    func addTrailing(_ codeGrid: CodeGrid, to other: CodeGrid) {
        snapping.connectWithInverses(sourceGrid: other, to: .right(codeGrid))
        codeGrid.rootNode.position = other.rootNode.position.translated(
            dX: other.measures.lengthX + 8.0,
            dY: 0,
            dZ: 0
        )
        lastFocusedGrid = codeGrid
    }
    
    func addInNextRow(_ codeGrid: CodeGrid, from other: CodeGrid) {
        snapping.connectWithInverses(sourceGrid: other, to: .down(codeGrid))
        lastFocusedGrid = codeGrid
        var maxHeight: VectorFloat = 0.0
        var leftMostGrid: CodeGrid?
        snapping.iterateOver(other, direction: .left) { _, grid, _ in
            maxHeight = max(maxHeight, grid.measures.lengthY)
            leftMostGrid = grid
        }
        
        codeGrid.rootNode.position = (
            leftMostGrid?.rootNode.position ?? .zero
        ).translated(
            dX: 0,
            dY: -maxHeight - 8.0,
            dZ: 0
        )
    }
    
    func addInNextPlane(_ codeGrid: CodeGrid, from other: CodeGrid) {
        snapping.connectWithInverses(sourceGrid: other, to: .backward(codeGrid))
        lastFocusedGrid = codeGrid
        codeGrid.rootNode.position = other.rootNode.position.translated(
            dX: 0,
            dY: 0,
            dZ: -64.0
        )
    }
}

// TODO: Does focus belong on editor? Probably. Maybe better state?
extension WorldGridEditor {
    func shiftFocus(_ shiftDirection: SelfRelativeDirection) {
        guard let lastGrid = lastFocusedGrid else {
            print("No grid to shift focus from; check that at least one transform completed")
            return
        }
        
        let relativeGrids = snapping.gridsRelativeTo(lastGrid, shiftDirection)
        print("Available grids on \(shiftDirection): \(relativeGrids.count)")
        
        guard let firstAvailableGrid = relativeGrids.first else {
            return
        }
        
        lastFocusedGrid = firstAvailableGrid.targetGrid
    }
}

extension WorldGridEditor {
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
}
