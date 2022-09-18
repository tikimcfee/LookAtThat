//
//  WorldGridEditor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import Foundation
import simd

var default__VerticalSpacing: VectorFloat = 4.0
var default__HorizontalSpacing: VectorFloat = 4.0
var default__PlaneSpacing: VectorFloat = 300.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 64.0

class WorldGridEditor {
    enum Strategy {
        case collection(target: GlyphCollection)
        case gridRelative
    }
    
    let snapping = WorldGridSnapping()
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
            //        case let (.trailingFromLastGrid(codeGrid), .collection(targetCollection)):
            //            addTrailing(codeGrid, from: lastGrid, inCollection: targetCollection)
            //
            //        case let (.inNextRow(codeGrid), .collection(targetCollection)):
            //            addInNextRow(codeGrid, from: lastGrid, inCollection: targetCollection)
            //
            //        case let (.inNextPlane(codeGrid), .collection(targetCollection)):
            //            addInNextPlane(codeGrid, from: lastGrid, inCollection: targetCollection)
            
        default:
            print("\n\nNot implemented! : \(layoutStrategy)")
        }
        
        return self
    }
}

// MARK: - Collection relative

extension WorldGridEditor {
    func addTrailing(
        _ grid: CodeGrid,
        from otherGrid: CodeGrid,
        inCollection collection: GlyphCollection
    ) {
        //        let xOffset = otherGrid.trailing + 4.0
        //        grid.updateAllNodeConstants { node, nodeConstants, _ in
        //            node.position.x += xOffset
        //            return nodeConstants
        //        }
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
        
        codeGrid
            .setLeading(other.trailing + default__HorizontalSpacing)
            .setTop(other.top)
            .setFront(other.front)
        
        lastFocusedGrid = codeGrid
    }
    
    func addInNextRow(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .down(codeGrid))
        lastFocusedGrid = codeGrid
        var lowestBottomPosition: VectorFloat = other.bottom
        var leftMostGrid: CodeGrid?
        
        snapping.iterateOver(other, direction: .left) { _, grid, _ in
            /* do this to have everything connected? */
//            self.snapping.connectWithInverses(sourceGrid: grid, to: .down(codeGrid))
            lowestBottomPosition = min(lowestBottomPosition, grid.bottom)
            leftMostGrid = grid
        }
        
        if let leftMostGrid = leftMostGrid {
            codeGrid
                .setLeading(leftMostGrid.leading)
                .setFront(leftMostGrid.front)
                .setTop(lowestBottomPosition - default__VerticalSpacing)
        } else {
            codeGrid
                .setLeading(other.leading)
                .setFront(other.front)
                .setTop(lowestBottomPosition - default__VerticalSpacing)
        }
    }
    
    func addInNextPlane(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .forward(codeGrid))
        lastFocusedGrid = codeGrid
        codeGrid
            .setLeading(0)
            .setTop(0)
            .setFront(other.back - default__PlaneSpacing)
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

