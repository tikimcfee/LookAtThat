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
    ) throws {
        try onAllCachedInfo { sourceGrid, clone, infoSet in
            let filteredSemantics = infoSet.filter { info in
                return info.referenceName.containsMatch(searchText)
            }
            let toCall = filteredSemantics.isEmpty ? onNegative : onPositive
            try toCall(sourceGrid, clone, filteredSemantics)
        }
    }
    
    // Loops through all grids, iterates over all SemanticInfo constructed for it
    func onAllCachedInfo(_ receiver: SearchReceiver) throws {
        for (cachedGrid, clone) in cache.cachedGrids.values {
            let items = Set(
                cachedGrid.codeGridSemanticInfo
                    .semanticsLookupBySyntaxId
                    .values
            )
            try receiver(cachedGrid, clone, items)
        }
    }
}
