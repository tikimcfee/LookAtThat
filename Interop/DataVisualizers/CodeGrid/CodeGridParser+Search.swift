//
//  CodeGridParser+Search.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation

class ParserQueryController: ObservableObject {
    typealias SearchReceiver = (
        _ source: CodeGrid,
        _ clone: CodeGrid,
        _ semantics: Set<SemanticInfo>
    ) throws -> Void
    
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
        onPositive: SearchReceiver,
        onNegative: SearchReceiver
    ) {
        onAllCachedInfo { sourceGrid, clone, infoSet in
            let filteredSemantics = infoSet.filter { info in
                if info.isFullTextSearchable {
                    return info.referenceName.fuzzyMatch(searchText)
                        || info.fullTextSearch.containsMatch(searchText)
                } else {
                    return info.referenceName.fuzzyMatch(searchText)
                }
            }
            let toCall = filteredSemantics.isEmpty ? onNegative : onPositive
            try toCall(sourceGrid, clone, filteredSemantics)
        }
    }
    
    // Loops through all grids, iterates over all SemanticInfo constructed for it
    func onAllCachedInfo(_ receiver: SearchReceiver) {
        for (cachedGrid, clone) in cache.cachedGrids.values {
            let items = Set(
                cachedGrid.codeGridSemanticInfo
                    .semanticsLookupBySyntaxId
                    .values
            )
            do {
                try receiver(cachedGrid, clone, items)
            } catch {
                print("Walk received error: \(error)")
                return
            }
        }
    }
    
//    func forAllGrids(_ receiver: (CodeGrid) -> Void) {
//        for cachedGrid in cache.cachedGrids.values {
//            receiver(cachedGrid)
//        }
//    }
}
