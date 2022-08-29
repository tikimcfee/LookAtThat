//
//  CodeGridParser+Search.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation

//MARK: - Observable controller

class CodeGridParserQueryController: ObservableObject {
    private var cache: GridCache { GlobalInstances.gridStore.gridCache }
    
    @Published var searchInput: String = ""

    init() {
        
    }
}

//MARK: - Search walk

extension CodeGridParserQueryController {
    func resetAllGridFocusLevels() {
        cache.tokenCache.doOnEach { _, nodeSet in
            nodeSet.forEach { $0.focus(level: 0) }
        }
    }
    
    func walkGridsForSearch(
        _ searchText: String,
        onPositive: SearchReceiver,
        onNegative: NegativeReceiver
    ) throws {
        resetAllGridFocusLevels()
        for grid in cache.cachedGrids.values {
            var matches = Set<SemanticInfo>()
            
            for (_, info) in grid.semanticInfoMap.semanticsLookupBySyntaxId {
                if info.referenceName.containsMatch(searchText) {
                    matches.insert(info)
                }
            }
            
            if matches.isEmpty {
                try onNegative(grid)
            } else {
                try onPositive(grid, matches)
            }
        }
    }
}

//MARK: - Aliases

extension CodeGridParserQueryController {
    typealias SearchReceiver = (
        _ source: CodeGrid,
        _ semantics: Set<SemanticInfo>
    ) throws -> Void
    
    typealias NegativeReceiver = (
        _ source: CodeGrid
    ) throws -> Void
}
