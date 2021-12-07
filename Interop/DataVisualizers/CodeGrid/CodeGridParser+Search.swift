//
//  CodeGridParser+Search.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation

class ParserQueryController: ObservableObject {
    let parser: CodeGridParser
    var tokenCache: CodeGridTokenCache { parser.tokenCache }
    var cache: GridCache { parser.gridCache }
    
    @Published var searchInput: String = ""
    lazy var searchBinding = WrappedBinding("", onSet: { self.searchInput = $0 })
    lazy var searchStream = $searchInput.share().eraseToAnyPublisher()
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func walkGridsForSearch(
        _ searchText: String,
        onPositive: (CodeGrid, Set<SemanticInfo>) throws -> Void,
        onNegative: (CodeGrid, Set<SemanticInfo>) throws -> Void
    ) {
        onAllCachedInfo { grid, infoSet in
            let filteredSemantics = infoSet.filter { info in
                if info.isFullTextSearchable {
                    return info.referenceName.fuzzyMatch(searchText)
                        || info.fullTextSearch.containsMatch(searchText)
                } else {
                    return info.referenceName.fuzzyMatch(searchText)
                }
            }
            let toCall = filteredSemantics.isEmpty ? onNegative : onPositive
            try toCall(grid, filteredSemantics)
        }
    }
    
    // Loops through all grids, iterates over all SemanticInfo constructed for it
    func onAllCachedInfo(_ receiver: (CodeGrid, Set<SemanticInfo>) throws -> Void) {
        for cachedGrid in cache.cachedGrids.values {
            let items = Set(
                cachedGrid.codeGridSemanticInfo
                    .semanticsLookupBySyntaxId
                    .values
            )
            do {
                try receiver(cachedGrid, items)
            } catch {
                print("Walk received error: \(error)")
                return
            }
        }
    }
    
    func forAllGrids(_ receiver: (CodeGrid) -> Void) {
        for cachedGrid in cache.cachedGrids.values {
            receiver(cachedGrid)
        }
    }
}
