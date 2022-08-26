//
//  CodeGridGlobalSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/12/22.
//

import Foundation
import SwiftSyntax

typealias AssociatedSyntaxMapSnapshot = [CodeGridSemanticMap.Category: [(SyntaxIdentifier, [SyntaxIdentifier])]]

class GlobalSemanticParticipant {
    let sourceGrid: CodeGrid
    var queryCategories = [CodeGridSemanticMap.Category]()
    var snapshot = AssociatedSyntaxMapSnapshot()
    
    init(grid: CodeGrid) {
        self.sourceGrid = grid
    }
    
    func updateQuerySnapshot() {
        snapshot = queryCategories.reduce(into: AssociatedSyntaxMapSnapshot()) { result, category in
            sourceGrid.codeGridSemanticInfo.category(category) { categoryMap in
                guard !categoryMap.isEmpty else { return }
                categoryMap.forEach { rootId, associationStore in
                    // TODO: Feels gross making a new array out of the store keys.
                    // Find a structure with fast insertions / contains (removals are not important)
                    // that also supports random access lookup.
                    result[category, default: []].append((rootId, Array(associationStore.keys)))
                }
            }
        }
    }
}

extension GlobalSemanticParticipant: Identifiable, Hashable {
    var id: ID { sourceGrid.id }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (_ left: GlobalSemanticParticipant, _ right: GlobalSemanticParticipant) -> Bool {
        return left.id == right.id
    }
}

public class CodeGridGlobalSemantics: ObservableObject {
    // This can be in the hundreds / thousands, but I need a flat array at some point, so no map
    typealias Snapshot = [GlobalSemanticParticipant]
    @Published var categorySnapshot = Snapshot()
    
    let source: GridCache
    
    init(source: GridCache) {
        self.source = source
    }
    
    var defaultCategories: [CodeGridSemanticMap.Category] {[
        .structs,
        .classes,
        .enumerations,
        .functions,
        .typeAliases,
        .protocols,
        .extensions,
        .switches
    ]}
    
    func snapshotDefault() {
        let watch = Stopwatch(running: true)
        print("Snapshot starting: \(self.source.cachedGrids.count)")
        categorySnapshot = snapshot(categories: defaultCategories)
        print("Snapshot complete: \(watch.elapsedTimeString())")
        watch.stop()
    }
    
    func snapshot(categories: [CodeGridSemanticMap.Category]) -> Snapshot {
        var globalParticipants = AutoCache<GlobalSemanticParticipant.ID, GlobalSemanticParticipant>()
        
        // Two passes
        // 1. collect all the participating grids that have values
        source.cachedGrids.directWriteAccess { mutableGridStore in
            for (_, grid) in mutableGridStore {
                for category in categories {
                    grid.codeGridSemanticInfo.category(category) { map in
                        guard !map.isEmpty else { return }
                        let participant = globalParticipants.retrieve(
                            key: grid.id,
                            defaulting: GlobalSemanticParticipant(grid: grid)
                        )
                        participant.queryCategories.append(category)
                    }
                }
            }
        }
        
        // 2. snapshot collection
        for participant in globalParticipants.source.values {
            participant.updateQuerySnapshot()
        }
        
        return Array(globalParticipants.source.values)
    }
}
