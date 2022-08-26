//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SwiftUI

class GridCache {
    typealias CacheValue = (source: CodeGrid, clone: CodeGrid)
    let parser: CodeGridParser
    let cachedGrids = ConcurrentDictionary<CodeGrid.ID, CacheValue>()
    var cachedFiles = ConcurrentDictionary<URL, CodeGrid.ID>()
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = (key, key.makeClone())
    }
    
    func setCache(_ key: URL, _ setOriginalAsClone: Bool = true) -> CodeGrid {
        let newGrid = parser.renderGrid(key) ?? {
            print("Could not render path \(key)")
            return parser.createNewGrid()
        }()
        
        let newCacheValue = setOriginalAsClone
            ? (source: newGrid, clone: newGrid)
            : (source: newGrid, clone: newGrid.makeClone())
        
        cachedGrids[newGrid.id] = newCacheValue
        cachedFiles[key] = newGrid.id
        return newGrid
    }
    
    func getOrCache(_ key: URL) -> CodeGrid {
        if let gridId = cachedFiles[key],
           let grid = cachedGrids[gridId] {
            return grid.source
        }
        
        return setCache(key)
    }
    
    func get(_ key: URL) -> CacheValue? {
        guard let cachedId = cachedFiles[key] else { return nil }
        return cachedGrids[cachedId]
    }
}
