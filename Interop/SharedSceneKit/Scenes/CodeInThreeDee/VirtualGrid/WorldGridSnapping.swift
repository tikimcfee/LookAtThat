//
//  WorldGridSnapping.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/19/21.
//

import Foundation

class WorldGridSnapping {
    // map the relative directions you can go from a grid
    // - a direction has a reference to target grid, such that it can become a 'focus'
    // grid -> Set<Direction> = {left(toLeft), right(toRight), down(below), forward(zFront)}
    enum RelativeGridMapping {
        case left(CodeGrid)
        case right(CodeGrid)
        case up(CodeGrid)
        case down(CodeGrid)
        case forward(CodeGrid)
        case backward(CodeGrid)
    }
    
    typealias Mapping = [CodeGrid: Set<RelativeGridMapping>]
    typealias Directions = Set<RelativeGridMapping>
    var mapping = Mapping()
}

extension WorldGridSnapping {
    func connect(sourceGrid: CodeGrid, to newDirectionalGrids: Directions) {
        var toUnion = mapping[sourceGrid] ?? {
            let directions = Directions()
            mapping[sourceGrid] = directions
            return directions
        }()
        toUnion.formUnion(newDirectionalGrids)
        mapping[sourceGrid] = toUnion
    }
    
    func connectWithInverses(sourceGrid: CodeGrid, to newDirectionalGrids: Directions) {
        connect(sourceGrid: sourceGrid, to: newDirectionalGrids)
        for mapping in newDirectionalGrids {
            switch mapping {
            case let .right(grid):
                connect(sourceGrid: grid, to: [.left(sourceGrid)])
            case let .left(grid):
                connect(sourceGrid: grid, to: [.right(sourceGrid)])
                
            case let .up(grid):
                connect(sourceGrid: grid, to: [.down(sourceGrid)])
            case let .down(grid):
                connect(sourceGrid: grid, to: [.up(sourceGrid)])
                
            case let .forward(grid):
                connect(sourceGrid: grid, to: [.backward(sourceGrid)])
            case let .backward(grid):
                connect(sourceGrid: grid, to: [.forward(sourceGrid)])
            }
        }
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid) -> Set<RelativeGridMapping> {
        return mapping[targetGrid] ?? []
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid, _ direction: SelfRelativeDirection) -> Set<RelativeGridMapping> {
        gridsRelativeTo(targetGrid).filter { $0 == direction }
    }
    
    func iterateOver(
        _ codeGrid: CodeGrid,
        direction: SelfRelativeDirection,
        _ receiver: @escaping (CodeGrid) -> Void
    ) {
        var relativeGrids = gridsRelativeTo(codeGrid, direction)
        while !relativeGrids.isEmpty {
            guard let nextGrid = relativeGrids.first?.targetGrid else {
                print("I was lied to about things not being empty")
                return
            }
            receiver(nextGrid)
            relativeGrids = gridsRelativeTo(nextGrid, direction)
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
