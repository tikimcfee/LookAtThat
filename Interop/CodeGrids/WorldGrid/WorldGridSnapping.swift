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
    typealias Relationship = SourcedRelativeGridMapping
    
    enum RelativeGridMapping {
        case left(CodeGrid)
        case right(CodeGrid)
        case up(CodeGrid)
        case down(CodeGrid)
        case forward(CodeGrid)
        case backward(CodeGrid)
        
        static func make(_ direction: SelfRelativeDirection, _ grid: CodeGrid) -> RelativeGridMapping {
            switch direction {
            case .left:
                return .left(grid)
            case .right:
                return .right(grid)
            case .up:
                return .up(grid)
            case .down:
                return .down(grid)
            case .forward:
                return .forward(grid)
            case .backward:
                return .backward(grid)
            }
        }
    }
    
    struct SourcedRelativeGridMapping {
        let parent: CodeGrid
        let mapping: RelativeGridMapping
    }
    
    private typealias Mapping = [CodeGrid: [Relationship]]
    private var mapping = Mapping()
    
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
    
    func connect(sourceGrid: CodeGrid, to relativeDirection: RelativeGridMapping) {
        var toInsert = mapping[sourceGrid] ?? {
            let new = [Relationship]()
            mapping[sourceGrid] = new
            return new
        }()
        
        guard !toInsert.contains(where: { $0.mapping == relativeDirection }) else {
            print("Skipping add; \(relativeDirection) exists")
            return
        }
        toInsert.append(SourcedRelativeGridMapping(parent: sourceGrid, mapping: relativeDirection))
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
    
    func detachRetaining(_ targetGrid: CodeGrid) {
        guard let detachedRelationships = mapping.removeValue(forKey: targetGrid) else {
            print("Nothing to detach for \(targetGrid)")
            return
        }
        
        print("Detach \(targetGrid.id)")
        
        var repairable: [Relationship] = []
        
        let allKeys = Array(mapping.keys)
        for key in allKeys {
            mapping[key]?.removeAll(where: { relationship in
                let foundMatch = relationship.mapping.targetGrid.id == targetGrid.id
                if foundMatch { repairable.append(relationship) }
                return foundMatch
            })
        }

        for potentialParent in repairable {
            for detachedRelationship in detachedRelationships {
                let matchesDirection = potentialParent.mapping.direction == detachedRelationship.mapping.direction
                let isNotMe = potentialParent.mapping.targetGrid.id != detachedRelationship.mapping.targetGrid.id
                if matchesDirection && isNotMe {
                    print("-- found match: [\(potentialParent.parent.id)] \(potentialParent.mapping)")
                    connect(sourceGrid: potentialParent.parent, to: detachedRelationship.mapping)
                } else {
                    print("-- skip match: direction:\(matchesDirection) isNotMe:\(isNotMe)")
                }
            }   
        }
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid) -> [RelativeGridMapping] {
        return mapping[targetGrid]?.map { $0.mapping } ?? []
    }
    
    func gridsRelativeTo(_ targetGrid: CodeGrid, _ direction: SelfRelativeDirection) -> [RelativeGridMapping] {
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
                receiver(previousGrid, nextTargetGrid, &stop)
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
