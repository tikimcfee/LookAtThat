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
        case atFocusPosition(CodeGrid, FocusPosition)
        var grid: CodeGrid {
            switch self {
            case .trailingFromLastGrid(let codeGrid):
                return codeGrid
            case .inNextRow(let codeGrid):
                return codeGrid
            case .inNextPlane(let codeGrid):
                return codeGrid
            case .atFocusPosition(let codeGrid, _):
                return codeGrid
            }
        }
    }
}

class WorldGridEditor {
    private var cache = WorldGrid()
    
    var focusPosition: FocusPosition = FocusPosition()
    var lastFocusedGrid: CodeGrid?
    
    init() {
        let bigBangRow = [CodeGrid]()
        let bigBangPlane = [bigBangRow]
        cache.append(bigBangPlane)
    }
    
    @discardableResult
    func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        switch style {
        case .atFocusPosition(let codeGrid, let requestPosition):
            // This is a our 'blit' function. It is going to start terribly.
            // If the position is not available because the array is too small,
            // then we'll recreate with empty grids, and find a way to jump
            // between spot. Again, a bad idea.
            break
            
        case .trailingFromLastGrid(let codeGrid):
            while focusPosition.z >= cache.indices.upperBound {
                print("Adding new plane at index \(cache.count - 1)")
                cache.append(WorldGridPlane())
            }
            
            var updatePlane = cache[focusPosition.z]
            while focusPosition.y >= updatePlane.indices.upperBound {
                print("Adding new row at index \(updatePlane.count - 1)")
                updatePlane.append(WorldGridRow())
            }
            cache[focusPosition.z] = updatePlane
            
            let row = updatePlane[focusPosition.y]
            
            
            updateRow(z: focusPosition.z, y: focusPosition.y) { row in
                while focusPosition.x >= row.indices.upperBound {
                    print("Adding new empty grid at index \(row.count - 1)")
                    row.append(CodeGridEmpty.make())
                }
                
                let lastDimensions = lastGridDimensions
                let isFirst = row.isEmpty
                row.append(codeGrid)
                
                codeGrid.rootNode.position = lastDimensions.position.translated(
                    dX: lastDimensions.size.lengthX + (isFirst ? 0 : 8.0)
                )
                
                if !isFirst {
                    focusPosition.right()
                }
            }
            
        case .inNextRow(let codeGrid):
            updatePlane(z: focusPosition.z) { plane in
                let lastDimensions = lastGridDimensions
                let lastRow = plane.last ?? []
                
                var newRow = WorldGridRow()
                newRow.append(codeGrid)
                plane.append(newRow)
                
                let maxRowHeight = lastRow.reduce(into: VectorFloat(0.0)) { height, grid in
                    height = max(height, grid.rootNode.lengthY)
                }
                let finalY = lastDimensions.position.y
                - maxRowHeight
                - 16.0
                
                codeGrid.rootNode.position = SCNVector3(
                    x: lastDimensions.position.x,
                    y: finalY,
                    z: lastDimensions.position.z
                )
                
                focusPosition.x = 0
                if !lastRow.isEmpty {
                    focusPosition.down()
                }
            }
            
        case .inNextPlane(let codeGrid):
            let lastDimensions = lastGridDimensions
            
            var newPlane = WorldGridPlane()
            var newRow = WorldGridRow()
            newRow.append(codeGrid)
            newPlane.append(newRow)
            cache.append(newPlane)
            
            codeGrid.rootNode.position = SCNVector3(
                x: lastDimensions.position.x,
                y: lastDimensions.position.y,
                z: lastDimensions.position.z - default__PlaneSpacing
            )
            
            //            focusPosition.x = 0
            //            focusPosition.y = 0
            focusPosition.forward()
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
    
    func iterateColumn(
        x: Int,
        z: Int,
        _ onIterate: @escaping (CodeGrid) -> Void
    ) {
        updatePlane(z: z) { columnPlane in
            // number of rows in grid; iterate from 0 to last row
            let planeHeight = columnPlane.count
            
            (0...planeHeight).forEach { rowIndex in
                guard columnPlane.indices.contains(rowIndex) else {
                    print("Invalid row iteration at \(x)")
                    return
                }
                
                let rowForColumn = columnPlane[rowIndex]
                guard rowForColumn.indices.contains(x) else {
                    print("Invalid column iteration at \(x)")
                    return
                }
                
                let gridAtColumn = rowForColumn[x]
                onIterate(gridAtColumn)
            }
        }
    }
}

extension WorldGridEditor {
    
    func countGridsInColumn(_ z: Int, _ x: Int) -> Int {
        var count = 0
        iterateColumn(x: x, z: z) { _ in count += 1}
        return count
    }
    
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
        else {
            print("grid miss at z:\(z)")
            return
        }
        operation(cache[z])
    }
    
    func readRowAt(z: Int, y: Int, _ operation: (WorldGridRow) -> Void) {
        guard cache.indices.contains(z),
              cache[z].indices.contains(y)
        else {
            print("grid miss at y:\(y), z:\(z)")
            return
        }
        operation(cache[z][y])
    }
    
    func readGridAt(z: Int, y: Int, x: Int) -> CodeGrid? {
        guard cache.indices.contains(z),
              cache[z].indices.contains(y),
              cache[z][y].indices.contains(x)
        else {
            print("grid miss at x:\(x), y:\(y), z:\(z)")
            return nil
        }
        return cache[z][y][x]
    }
    
    var gridAtFocusPosition: CodeGrid? {
        print("return grid at \(focusPosition)")
        return readGridAt(z: focusPosition.z, y: focusPosition.y, x: focusPosition.x)
    }
    
    var lastGridDimensions: (
        position: SCNVector3,
        size: (lengthX: VectorFloat, lengthY: VectorFloat, lengthZ: VectorFloat)
    ) {
        let gridAtFocusPosition = gridAtFocusPosition
        return (
            gridAtFocusPosition?.rootNode.position ?? SCNVector3Zero,
            (
                gridAtFocusPosition?.backgroundGeometryNode.lengthX ?? 0.0,
                gridAtFocusPosition?.backgroundGeometryNode.lengthY ?? 0.0,
                gridAtFocusPosition?.backgroundGeometryNode.lengthZ ?? 0.0
            )
        )
    }
}

extension WorldGridEditor {
    func shiftFocus(_ direction: SelfRelativeDirection) {
        switch direction {
        case .forward:
            guard focusPosition.z < countPlanes() - 1 else { return }
            focusPosition.forward()
            focusPosition.x = max(0, min(focusPosition.x, countGridsInRow(focusPosition.z, focusPosition.y) - 1))
            focusPosition.y = max(0, min(focusPosition.y, countRowsInPlane(focusPosition.z) - 1))
        case .backward:
            focusPosition.backward()
            focusPosition.x = max(0, min(focusPosition.x, countGridsInRow(focusPosition.z, focusPosition.y) - 1))
            focusPosition.y = max(0, min(focusPosition.y, countRowsInPlane(focusPosition.z) - 1))
        case .left:
            focusPosition.left()
            focusPosition.y = max(0, min(focusPosition.y, countRowsInPlane(focusPosition.z) - 1))
        case .right:
            guard focusPosition.x < countGridsInRow(focusPosition.z, focusPosition.y) - 1 else { return }
            focusPosition.right()
            focusPosition.y = max(0, min(focusPosition.y, countRowsInPlane(focusPosition.z) - 1))
        case .up:
            focusPosition.up()
            focusPosition.x = max(0, min(focusPosition.x, countGridsInRow(focusPosition.z, focusPosition.y) - 1))
        case .down:
            guard focusPosition.y < countRowsInPlane(focusPosition.z) - 1 else { return }
            focusPosition.down()
            focusPosition.x = max(0, min(focusPosition.x, countGridsInRow(focusPosition.z, focusPosition.y) - 1))
        }
    }
}

class CodeGridSnapping {
    // map the relative directions you can go from a grid
    // - a direction has a reference to target grid, such that it can become a 'focus'
    // grid -> Set<Direction> = {left(toLeft), right(toRight), down(below), forward(zFront)}
    enum RelativeGridMapping: Hashable {
        case left(CodeGrid)
        case right(CodeGrid)
        case up(CodeGrid)
        case down(CodeGrid)
        case forward(CodeGrid)
        case backward(CodeGrid)
        
        var targetGrid: CodeGrid {
            switch self {
            case let .left(grid),
                 let .right(grid),
                 let .up(grid),
                 let .down(grid),
                 let .forward(grid),
                let .backward(grid):
                return grid
            }
        }
        
        var direction: SelfRelativeDirection {
            switch self {
            case .left: return .left
            case .right: return .right
            case .up: return .up
            case .down: return .down
            case .forward: return .forward
            case .backward: return .backward
            }
        }
        
        static func == (_ relativeMapping: RelativeGridMapping, _ direction: SelfRelativeDirection) -> Bool {
            return relativeMapping.direction == direction
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(targetGrid.id)
        }
    }
    
    typealias Mapping = [CodeGrid: Set<RelativeGridMapping>]
    typealias Directions = Set<RelativeGridMapping>
    var mapping = Mapping()
    
    func connect(sourceGrid: CodeGrid, to newDirectionalGrids: Directions) {
        var toUnion = mapping[sourceGrid] ?? {
            let directions = Directions()
            mapping[sourceGrid] = directions
            return directions
        }()
        toUnion.formUnion(newDirectionalGrids)
        mapping[sourceGrid] = toUnion
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid) -> Set<RelativeGridMapping> {
        return mapping[targetGrid] ?? []
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid, _ direction: SelfRelativeDirection) -> Set<RelativeGridMapping> {
        gridsRelativeTo(targetGrid).filter { $0 == direction }
    }
}

extension CodeGrid: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
