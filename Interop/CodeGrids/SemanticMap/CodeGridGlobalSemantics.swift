//
//  CodeGridGlobalSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/12/22.
//
// This whole thing just remaps everything from a bunch of grids at once without getting
// *everything*, like every text node or variable. High level stuff.
//

import Foundation
import SwiftSyntax

// A mapping of a category to an array of tuples that associate a given SyntaxID
// with all of the other IDs related to it.
typealias AssociatedSyntaxMapSnapshot = [
    SemanticInfoMap.Category: [(SyntaxIdentifier, [SyntaxIdentifier])]
]

class GlobalSemanticParticipant: Identifiable {
    var id: String { sourceGrid.id }
    
    let sourceGrid: CodeGrid
    var queryCategories = [SemanticInfoMap.Category]()
    var snapshot = AssociatedSyntaxMapSnapshot()
    
    init(grid: CodeGrid) {
        self.sourceGrid = grid
    }
    
    func updateQuerySnapshot() {
        // Start creating a snapshot of all known IDs for that category.
        snapshot = queryCategories.reduce(into: AssociatedSyntaxMapSnapshot()) { result, category in
            sourceGrid.semanticInfoMap.category(category) { categoryMap in
                guard !categoryMap.isEmpty else { return }
                categoryMap.forEach { rootId, associationStore in
                    result[category, default: []].append((rootId, Array(associationStore.keys)))
                }
            }
        }
    }
}

extension GlobalSemanticParticipant: Hashable {
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
    
    var defaultCategories: [SemanticInfoMap.Category] {[
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
    
    func snapshot(categories: [SemanticInfoMap.Category]) -> Snapshot {
        var globalParticipants = AutoCache<GlobalSemanticParticipant.ID, GlobalSemanticParticipant>()
        
        // Two passes
        // 1. collect all the participating grids that have values
        source.cachedGrids.directWriteAccess { mutableGridStore in
            for (_, grid) in mutableGridStore {
                for category in categories {
                    grid.semanticInfoMap.category(category) { map in
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
       
        // 3. sort
        let participants = globalParticipants.source.values
//        let sorted = JSSorter().pathsort(sortable: Array(participants))
        participants.forEach { print($0.sourceGrid.sourcePath!) }
        return Array(participants)
    }
}

protocol URLSortable {
    var components: [String] { get }
}

extension GlobalSemanticParticipant: URLSortable {
    var components: [String] {
        sourceGrid.sourcePath?.pathComponents ?? {
            print("grid is missing path -->", sourceGrid.fileName, sourceGrid.id)
            return []
        }()
    }
}


class JSSorter {
    func pathsort<T: URLSortable>(sortable: [T]) -> [T] {
        let sortedComponents = sortable.sorted(by: sorter)
        return Array(sortedComponents)
    }
    
    func sorter(left: URLSortable, right: URLSortable) -> Bool {
        var (
            leftIterator, rightIterator,
            leftCount, rightCount
        ) = (
            left.components.makeIterator(),
            right.components.makeIterator(),
            left.components.count,
            right.components.count
        )
        
        func getNextA() -> String? { leftIterator.next() }
        func getNextB() -> String? { rightIterator.next() }
        
        repeat {
            guard let nextA = getNextA() else { return true }
            guard let nextB = getNextB() else { return false }
            if nextA.uppercased() > nextB.uppercased() { return false }
            if nextA.uppercased() < nextB.uppercased() { return true }
            if (leftCount < rightCount) { return true }
            if (leftCount > rightCount) { return false }
        } while(true)
    }
}
