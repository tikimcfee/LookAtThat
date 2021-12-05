//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation

class SearchContainer {
    var codeGridFocus: CodeGridFocus
    var codeGridParser: CodeGridParser
    
    init(codeGridParser: CodeGridParser,
         codeGridFocus: CodeGridFocus) {
        self.codeGridParser = codeGridParser
        self.codeGridFocus = codeGridFocus
    }
    
    func search(_ newInput: String, _ state: SceneState) {
        print("new search ---------------------- [\(newInput)]")
        var toAdd: [CodeGrid] = []
        var toRemove: [CodeGrid] = []
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, leafInfo in
                toAdd.append(foundInGrid)
            },
            onNegative: { excludedGrid, leafInfo in
                toRemove.append(excludedGrid)
            }
        )
        sceneTransaction {
            toRemove.forEach {
                codeGridFocus.removeGridFromFocus($0)
            }
            toAdd.enumerated().forEach {
                codeGridFocus.addGridToFocus($0.element, $0.offset)
            }
            
        }
        print("----------------------")
    }
}
