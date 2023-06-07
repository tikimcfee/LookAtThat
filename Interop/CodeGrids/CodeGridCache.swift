//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SwiftUI
import BitHandling
import MetalLink

private extension GlyphCollection {
    static func makeFromGlobalDefaults() throws -> GlyphCollection {
        try GlyphCollection(
            link: GlobalInstances.defaultLink,
            linkAtlas: GlobalInstances.defaultAtlas
        )
    }
}

public class GridCache {
    public typealias CacheValue = CodeGrid
    public let cachedGrids = ConcurrentDictionary<CodeGrid.ID, CacheValue>()
    public var cachedFiles = ConcurrentDictionary<URL, CodeGrid.ID>()
    public var tokenCache: CodeGridTokenCache
    
    public init(tokenCache: CodeGridTokenCache = CodeGridTokenCache()) {
        self.tokenCache = tokenCache
    }
    
    public func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = key
    }
    
    public func setCache(_ key: URL) -> CodeGrid {
        let newGrid = renderGrid(key) ?? {
            print("Could not render path \(key)")
            return createNewGrid()
        }()
        
        cachedGrids[newGrid.id] = newGrid
        cachedFiles[key] = newGrid.id
        return newGrid
    }
    
    public func getOrCache(_ key: URL) -> CodeGrid {
        if let gridId = cachedFiles[key],
           let grid = cachedGrids[gridId] {
            return grid
        }
        
        return setCache(key)
    }
    
    public func get(_ key: URL) -> CacheValue? {
        guard let cachedId = cachedFiles[key] else { return nil }
        return cachedGrids[cachedId]
    }
    
    public func createNewGrid() -> CodeGrid {
        return CodeGrid(
            rootNode: try! GlyphCollection.makeFromGlobalDefaults(),
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
        let sourceFile = parse(source)
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
