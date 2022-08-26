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
    typealias CacheValue = CodeGrid
    let parser: CodeGridParser
    let cachedGrids = ConcurrentDictionary<CodeGrid.ID, CacheValue>()
    var cachedFiles = ConcurrentDictionary<URL, CodeGrid.ID>()
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = key
    }
    
    func setCache(_ key: URL, _ setOriginalAsClone: Bool = true) -> CodeGrid {
        let newGrid = parser.renderGrid(key) ?? {
            print("Could not render path \(key)")
            return parser.createNewGrid()
        }()
        
        cachedGrids[newGrid.id] = newGrid
        cachedFiles[key] = newGrid.id
        return newGrid
    }
    
    func getOrCache(_ key: URL) -> CodeGrid {
        if let gridId = cachedFiles[key],
           let grid = cachedGrids[gridId] {
            return grid
        }
        
        return setCache(key)
    }
    
    func get(_ key: URL) -> CacheValue? {
        guard let cachedId = cachedFiles[key] else { return nil }
        return cachedGrids[cachedId]
    }
}
