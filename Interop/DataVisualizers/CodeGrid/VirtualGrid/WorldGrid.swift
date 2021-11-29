//
//  WorldGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/6/21.
//

import Foundation
import SceneKit

var default__PlaneSpacing: VectorFloat = 256.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 128.0

typealias WorldGrid = [[[CodeGrid]]]
typealias WorldGridPlane = [[CodeGrid]]
typealias WorldGridRow = [CodeGrid]

enum SelfRelativeDirection: Hashable, CaseIterable {
    case forward
    case backward
    case left
    case right
    case up
    case down
}

struct FocusPosition: CustomStringConvertible, Equatable {
    var x: Int {
        didSet { pfocus() }
    }
    var y: Int {
        didSet { pfocus() }
    }
    var z: Int {
        didSet { pfocus() }
    }
    
    func pfocus() {
//        print("\(x), \(y), \(z)")
    }
    
    var description: String {
        "(\(x), \(y), \(z))"
    }
    
    init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    mutating func left() {
        x = max(0, x - 1)
    }
    
    mutating func right() {
        x = min(x + 1, Int.max - 2)
    }
    
    mutating func up() {
        y = max(0, y - 1)
    }
    
    mutating func down() {
        y = min(y + 1, Int.max - 2)
    }
    
    mutating func forward() {
        z = min(z + 1, Int.max - 2)
    }
    
    mutating func backward() {
        z = max(0, z - 1)
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
            snapping.connectWithInverses(sourceGrid: lastGrid, to: [.right(codeGrid)])
            codeGrid.rootNode.position = lastGrid.rootNode.position.translated(
                dX: lastGrid.measures.lengthX + 8.0,
                dY: 0,
                dZ: 0
            )
            lastFocusedGrid = codeGrid
            
        case .inNextRow(let codeGrid):
            snapping.connectWithInverses(sourceGrid: lastGrid, to: [.down(codeGrid)])
            lastFocusedGrid = codeGrid
            var maxHeight: VectorFloat = 0.0
            var leftMostGrid: CodeGrid?
            snapping.iterateOver(lastGrid, direction: .left) { grid in
                maxHeight = max(maxHeight, grid.measures.lengthY)
                leftMostGrid = grid
            }

            codeGrid.rootNode.position = (
                leftMostGrid?.rootNode.position ?? SCNVector3Zero
            ).translated(
                dX: 0,
                dY: -maxHeight - 8.0,
                dZ: 0
            )

        case .inNextPlane(let codeGrid):
            snapping.connectWithInverses(sourceGrid: lastGrid, to: [.backward(codeGrid)])
            lastFocusedGrid = codeGrid
            codeGrid.rootNode.position = lastGrid.rootNode.position.translated(
                dX: 0,
                dY: 0,
                dZ: 128.0
            )

        }
        return self
    }
    
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
