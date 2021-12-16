//
//  WorldGridSnapping.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/19/21.
//

import Foundation
import SceneKit

class WorldGridSnapping {
    // map the relative directions you can go from a grid
    // - a direction has a reference to target grid, such that it can become a 'focus'
    // grid -> Set<Direction> = {left(toLeft), right(toRight), down(below), forward(zFront)}
    typealias RelativeMappings = [RelativeGridMapping]
    
    enum RelativeGridMapping {
        case left(CodeGrid)
        case right(CodeGrid)
        case up(CodeGrid)
        case down(CodeGrid)
        case forward(CodeGrid)
        case backward(CodeGrid)
    }
    
    typealias Mapping = [CodeGrid: RelativeMappings]
    var mapping = Mapping()
    
    var gridReg1: CodeGrid?
    var gridReg2: CodeGrid?
    var gridReg3: CodeGrid?
    var gridReg4: CodeGrid?
    var nodeReg1: SCNNode?
    var nodeReg2: SCNNode?
    var nodeReg3: SCNNode?
    var nodeReg4: SCNNode?
}

extension WorldGridSnapping {
    func clearAll() {
        mapping.removeAll()
    }
    
    func connect(sourceGrid: CodeGrid, to newDirectionalGrids: RelativeGridMapping) {
        var toInsert = mapping[sourceGrid] ?? {
            let new = RelativeMappings()
            mapping[sourceGrid] = new
            return new
        }()
        guard !toInsert.contains(where: { $0 == newDirectionalGrids }) else {
            print("Skipping add; \(newDirectionalGrids) exists")
            return
        }
        toInsert.append(newDirectionalGrids)
        mapping[sourceGrid] = toInsert
    }
    
    func connectWithInverses(
        sourceGrid: CodeGrid,
        to newConnection: RelativeGridMapping
    ) {
        connect(sourceGrid: sourceGrid, to: newConnection)
        switch newConnection {
        case let .right(grid):
            connect(sourceGrid: grid, to: .left(sourceGrid))
        case let .left(grid):
            connect(sourceGrid: grid, to: .right(sourceGrid))
            
        case let .up(grid):
            connect(sourceGrid: grid, to: .down(sourceGrid))
        case let .down(grid):
            connect(sourceGrid: grid, to: .up(sourceGrid))
            
        case let .forward(grid):
            connect(sourceGrid: grid, to: .backward(sourceGrid))
        case let .backward(grid):
            connect(sourceGrid: grid, to: .forward(sourceGrid))
        }
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid) -> RelativeMappings {
        return mapping[targetGrid] ?? []
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid, _ direction: SelfRelativeDirection) -> RelativeMappings {
        gridsRelativeTo(targetGrid).filter { $0.direction == direction }
    }
    
    func iterateOver(
        _ codeGrid: CodeGrid,
        direction: SelfRelativeDirection,
        _ receiver: @escaping (CodeGrid?, CodeGrid, inout Bool) -> Void
    ) {
        var stop = false
        var nextTargetGrid = codeGrid
        var previousGrid = codeGrid
        var nextSet = gridsRelativeTo(nextTargetGrid, direction)
        
        while !stop, !nextSet.isEmpty {
            if nextSet.count == 1, let first = nextSet.first {
                nextTargetGrid = first.targetGrid
                receiver(previousGrid, first.targetGrid, &stop)
                nextSet = gridsRelativeTo(nextTargetGrid, direction)
                previousGrid = nextTargetGrid
            } else if let first = nextSet.first {
                print("Found multiple relations: \(nextSet)")
                nextTargetGrid = first.targetGrid
                nextSet.forEach { relation in
                    receiver(previousGrid, relation.targetGrid, &stop)
                }
                nextSet = gridsRelativeTo(nextTargetGrid, direction)
                previousGrid = nextTargetGrid
            } else {
                stop = true
            }
        }
    }
}

extension WorldGridSnapping.RelativeGridMapping {
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
    
    static func == (_ relativeMapping: WorldGridSnapping.RelativeGridMapping,
                    _ direction: SelfRelativeDirection) -> Bool {
        return relativeMapping.direction == direction
    }
}

extension WorldGridSnapping.RelativeGridMapping: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(targetGrid.id)
    }
}
