//
//  CodeGridParser+Search.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation

//MARK: - Observable controller

class CodeGridParserQueryController: ObservableObject {
    let parser: CodeGridParser
    private var cache: GridCache { parser.gridCache }
    
    @Published var searchInput: String = ""

    init(parser: CodeGridParser) {
        self.parser = parser
    }
}

//MARK: - Search walk

extension CodeGridParserQueryController {
    func resetAllGridFocusLevels() {
        cache.parser.tokenCache.doOnEach { _, nodeSet in
            nodeSet.forEach { $0.focus(level: 0) }
        }
    }
    
    func walkGridsForSearch(
        _ searchText: String,
        onPositive: SearchReceiver,
        onNegative: NegativeReceiver
    ) throws {
        resetAllGridFocusLevels()
        for cloneTuple in cache.cachedGrids.values {
            var matches = Set<SemanticInfo>()
            
            for (_, info) in cloneTuple.source.codeGridSemanticInfo.semanticsLookupBySyntaxId {
                if info.referenceName.containsMatch(searchText) {
                    matches.insert(info)
                }
            }
            
            if matches.isEmpty {
                try onNegative(cloneTuple.source, cloneTuple.clone)
            } else {
                try onPositive(cloneTuple.source, cloneTuple.clone, matches)
            }
        }
    }
}

//MARK: - Aliases

extension CodeGridParserQueryController {
    typealias SearchReceiver = (
        _ source: CodeGrid,
        _ clone: CodeGrid,
        _ semantics: Set<SemanticInfo>
    ) throws -> Void
    
    typealias NegativeReceiver = (
        _ source: CodeGrid,
        _ clone: CodeGrid
    ) throws -> Void
}
