//
//  WorldGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/6/21.
//

import Foundation

var default__VerticalSpacing: VectorFloat = 4.0
var default__HorizontalSpacing: VectorFloat = 4.0
var default__PlaneSpacing: VectorFloat = 128.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 64.0

typealias WorldGrid = [[[CodeGrid]]]
typealias WorldGridPlane = [[CodeGrid]]
typealias WorldGridRow = [CodeGrid]

class WorldGridEditor {
    enum Strategy {
        case collection(target: GlyphCollection)
        case gridRelative
    }
    
    private let snapping = WorldGridSnapping()
    var layoutStrategy: Strategy = .gridRelative
    
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
        
        switch (style, layoutStrategy) {
        // Grid Relative
        case let (.trailingFromLastGrid(codeGrid), .gridRelative):
            addTrailing(codeGrid, from: lastGrid)
            
        case let (.inNextRow(codeGrid), .gridRelative):
            addInNextRow(codeGrid, from: lastGrid)
            
        case let (.inNextPlane(codeGrid), .gridRelative):
            addInNextPlane(codeGrid, from: lastGrid)
            
        // Collection
        case let (.trailingFromLastGrid(codeGrid), .collection(targetCollection)):
            addTrailing(codeGrid, from: lastGrid, inCollection: targetCollection)
            
        case let (.inNextRow(codeGrid), .collection(targetCollection)):
            addInNextRow(codeGrid, from: lastGrid, inCollection: targetCollection)
            
        case let (.inNextPlane(codeGrid), .collection(targetCollection)):
            addInNextPlane(codeGrid, from: lastGrid, inCollection: targetCollection)
        }
        
        return self
    }
}

// MARK: - Collection relative
import simd
extension WorldGridEditor {    
    func addTrailing(
        _ grid: CodeGrid,
        from otherGrid: CodeGrid,
        inCollection collection: GlyphCollection
    ) {
        let xOffset = otherGrid.measures.trailing + 4.0
        grid.updateAllNodeConstants { node, nodeConstants, _ in
            node.position.x += xOffset
            return nodeConstants
        }
    }
    
    func addInNextRow(
        _ grid: CodeGrid,
        from otherGrid: CodeGrid,
        inCollection collection: GlyphCollection
    ) {
        
    }
    
    func addInNextPlane(
        _ grid: CodeGrid,
        from otherGrid: CodeGrid,
        inCollection collection: GlyphCollection
    ) {
        
    }
}

// MARK: - Grid relative

extension WorldGridEditor {
    func addTrailing(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .right(codeGrid))
        codeGrid.rootNode.position = other.rootNode.position.translated(
            dX: other.measures.lengthX + default__HorizontalSpacing
        )
        lastFocusedGrid = codeGrid
    }
    
    func addInNextRow(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .down(codeGrid))
        lastFocusedGrid = codeGrid
        var maxHeight: VectorFloat = 0.0
        var leftMostGrid: CodeGrid?
        snapping.iterateOver(other, direction: .left) { _, grid, _ in
            /* do this to have everything connected? */
//            snapping.connectWithInverses(sourceGrid: grid, to: .down(codeGrid))
            maxHeight = max(maxHeight, grid.measures.lengthY)
            leftMostGrid = grid
        }
        
        if let leftMostGrid = leftMostGrid {
            codeGrid.rootNode.position = leftMostGrid.rootNode.position.translated(
                dY: -maxHeight - default__VerticalSpacing
            )
        } else {
            codeGrid.rootNode.position = other.rootNode.position.translated(
                dY: -other.measures.lengthY - default__VerticalSpacing
            )
        }
    }
    
    func addInNextPlane(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .forward(codeGrid))
        lastFocusedGrid = codeGrid
        codeGrid.rootNode.position = LFloat3(
            x: 0,
            y: 0,
            z: other.rootNode.position.z - default__PlaneSpacing
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
