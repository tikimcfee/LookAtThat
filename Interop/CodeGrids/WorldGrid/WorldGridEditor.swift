//
//  WorldGridEditor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import Foundation
import simd
import MetalLink

var default__VerticalSpacing: VectorFloat = 4.0
var default__HorizontalSpacing: VectorFloat = 4.0
var default__PlaneSpacing: VectorFloat = 300.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 64.0

class WorldGridEditor {
    enum Strategy {
//        case collection(target: GlyphCollection)
        case gridRelative
    }
    
    let snapping = WorldGridSnapping()
    var layoutStrategy: Strategy = .gridRelative
    
    var lastFocusedGrid: CodeGrid?
    
    init() {
        
    }
    
    
    func applyAllUpdates(
        sizeSortedAdditions: [CodeGrid],
        sizeSortedMissing: [CodeGrid]
    ) {
        print(Array(repeating: "-", count: 64).joined(), "\n")
        
        snapping.clearAll()
        lastFocusedGrid = nil
        
        sizeSortedAdditions.first?.position = .zero
        sizeSortedMissing.first?.position = .zero
        
        let breakPoint = 12
        var gridCounter = 0
        var trailingBreakGrid: CodeGrid? {
            get { snapping.gridReg1 }
            set {
                snapping.gridReg1 = (
                    gridCounter > 0
                    && gridCounter % breakPoint == 0
                ) ? newValue : nil
                gridCounter += 1
            }
        }
        
        func layout(_ grid: CodeGrid) {
            if let _ = trailingBreakGrid {
                transformedByAdding(.inNextRow(grid))
            } else {
                transformedByAdding(.trailingFromLastGrid(grid))
            }
            trailingBreakGrid = grid
        }
        
        guard !sizeSortedAdditions.isEmpty else {
            sizeSortedMissing.forEach {
                layout($0)
            }
            return
        }
        
        // Layout additions first
        sizeSortedAdditions.forEach {
            layout($0)
        }
        
        // Get last grid (should be tallest if sorted) and offset.
        // Following grids will trail.
        if let firstMissing = sizeSortedMissing.first {
            transformedByAdding(.inNextPlane(firstMissing))
        }
        
        sizeSortedMissing.dropFirst().forEach {
            layout($0)
        }
        
    }
    
    @discardableResult
    func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        switch (style, layoutStrategy, lastFocusedGrid) {
        case (_, _, .none):
            print("Setting first focused grid: \(style)")
            lastFocusedGrid = style.grid
            
        case let (.trailingFromLastGrid(codeGrid), .gridRelative, .some(lastGrid)):
            addTrailing(codeGrid, from: lastGrid)
            
        case let (.inNextRow(codeGrid), .gridRelative, .some(lastGrid)):
            addInNextRow(codeGrid, from: lastGrid)
            
        case let (.inNextPlane(codeGrid), .gridRelative, .some(lastGrid)):
            addInNextPlane(codeGrid, from: lastGrid)
        }
        
        return self
    }
}

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
//        case topFromLastGrid(CodeGrid)
        
        var grid: CodeGrid {
            switch self {
            case let .trailingFromLastGrid(codeGrid):
                return codeGrid
            case let .inNextRow(codeGrid):
                return codeGrid
            case let .inNextPlane(codeGrid):
                return codeGrid
//            case let .topFromLastGrid(codeGrid):
//                return codeGrid
            }
        }
    }
}

