//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SwiftUI

private extension GlyphCollection {
    static func makeFromGlobalDefaults() -> GlyphCollection {
        GlyphCollection(
            link: GlobalInstances.defaultLink,
            linkAtlas: GlobalInstances.defaultAtlas
        )
    }
}

class GridCache {
    typealias CacheValue = CodeGrid
    let cachedGrids = ConcurrentDictionary<CodeGrid.ID, CacheValue>()
    var cachedFiles = ConcurrentDictionary<URL, CodeGrid.ID>()
    var tokenCache: CodeGridTokenCache
    
    init(tokenCache: CodeGridTokenCache = CodeGridTokenCache()) {
        self.tokenCache = tokenCache
    }
    
    func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = key
    }
    
    func setCache(_ key: URL, _ setOriginalAsClone: Bool = true) -> CodeGrid {
        let newGrid = renderGrid(key) ?? {
            print("Could not render path \(key)")
            return createNewGrid()
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
    
    func createNewGrid() -> CodeGrid {
        return CodeGrid(
            rootNode: GlyphCollection.makeFromGlobalDefaults(),
            tokenCache: tokenCache
        )
    }

}


extension GridCache: SwiftSyntaxFileLoadable {
    func renderGrid(_ url: URL) -> CodeGrid? {
        if FileBrowser.isSwiftFile(url) {
            guard let sourceFile = loadSourceUrl(url) else { return nil }
            let newGrid = createGridFromSyntax(sourceFile, url)
            return newGrid
        } else {
            return createGridFromFile(url)
        }
    }
    
    func renderGrid(_ source: String) -> CodeGrid? {
        guard let sourceFile = parse(source) else { return nil }
        let newGrid = createGridFromSyntax(sourceFile, nil)
        return newGrid
    }
    
    func createGridFromFile(_ url: URL) -> CodeGrid {
        let grid = createNewGrid()
            .applying {
                $0.withFileName(url.fileName)
                    .withSourcePath(url)
            }
        
        if let fileContents = try? String(contentsOf: url, encoding: .utf8) {
            grid.consume(text: fileContents)
        } else {
            print("Could not read contents at: \(url)")
        }
        
        return grid
    }
    
    func createGridFromSyntax(_ syntax: SourceFileSyntax, _ sourceURL: URL?) -> CodeGrid {
        let grid = createNewGrid()
            .consume(rootSyntaxNode: Syntax(syntax))
            .applying {
                if let url = sourceURL {
                    $0.withFileName(url.fileName)
                        .withSourcePath(url)
                }
            }
        
        return grid
    }
}
