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
    
    typealias Mapping = [CodeGrid: RelativeGridMapping]
    var mapping = Mapping()
    lazy var align = Align(snap: self)
    
    struct Align {
        enum Direction { case top, bottom }
        
        let snap: WorldGridSnapping
        
        func allToTop(root: CodeGrid, _ direction: Direction) {
            var lastGrid: CodeGrid = root
            snap.iterateOver(root, direction: .left) { leftGrid, _ in
                leftGrid.measures
                    .alignedToTopOf(lastGrid)
                    .alignedToLeadingOf(lastGrid)
                lastGrid = leftGrid
            }
            snap.iterateOver(root, direction: .right) { rightGrid, _ in
                rightGrid.measures
                    .alignedToTopOf(lastGrid)
                    .alignedToTrailingOf(lastGrid)
                lastGrid = rightGrid
            }
        }
    }
}

extension WorldGridSnapping {
    func clearAll() {
        mapping.removeAll()
    }
    
    func connect(sourceGrid: CodeGrid, to newDirectionalGrids: RelativeGridMapping) {
        mapping[sourceGrid] = newDirectionalGrids
    }
    
    func connectWithInverses(sourceGrid: CodeGrid, to newConnection: RelativeGridMapping) {
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
    
    func gridsRelativeTo(_ targetGrid: CodeGrid) -> RelativeGridMapping? {
        return mapping[targetGrid]
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid, _ direction: SelfRelativeDirection) -> Set<RelativeGridMapping> {
        if let relative = mapping[targetGrid],
           relative.direction == direction {
            return [relative]
        } else {
            return []
        }
    }
    
    func iterateOver(
        _ codeGrid: CodeGrid,
        direction: SelfRelativeDirection,
        _ receiver: @escaping (CodeGrid, inout Bool) -> Void
    ) {
        var relativeGrids = gridsRelativeTo(codeGrid, direction)
        var stop = false
        while !relativeGrids.isEmpty {
            guard let nextGrid = relativeGrids.first?.targetGrid else {
                print("I was lied to about things not being empty")
                return
            }
            
            print("-- Snap loop \(DispatchTime.now())--")
            
            receiver(nextGrid, &stop)
            if stop { return }
            
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
