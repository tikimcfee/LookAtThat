//
//  CodeGridParser+GridExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

// MARK: - Rendering requests
extension CodeGridParser {
    
    func withNewGrid(_ url: URL, _ operation: (CodeGridWorld, CodeGrid) -> Void) {
        if let grid = renderGrid(url) {
            operation(editorWrapper, grid)
        }
    }
    
    func withNewGrid(_ source: String, _ operation: (CodeGridWorld, CodeGrid) -> Void) {
        if let grid = renderGrid(source) {
            operation(editorWrapper, grid)
        }
    }
    
    func renderGrid(_ url: URL) -> CodeGrid? {
        guard let sourceFile = loadSourceUrl(url) else { return nil }
        let newGrid = createGridFromSyntax(sourceFile, url)
        return newGrid
    }
    
    func renderGrid(_ source: String) -> CodeGrid? {
        guard let sourceFile = parse(source) else { return nil }
        let newGrid = createGridFromSyntax(sourceFile, nil)
        return newGrid
    }
}

// MARK: - Builder helpers
extension CodeGridParser {
    func createNewGrid() -> CodeGrid {
        CodeGrid(
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
    }
    
    func createGridFromSyntax(_ syntax: SourceFileSyntax, _ sourceURL: URL?) -> CodeGrid {
        let grid = createNewGrid()
            .consume(syntax: Syntax(syntax))
            .sizeGridToContainerNode()
            .applying {
                if let url = sourceURL, let path = FileKitPath(url: url) {
                    $0.withFileName(path.fileName)
                }
            }
        
        return grid
    }
    
    func makeFileNameGrid(_ name: String) -> CodeGrid {
        let newGrid = createNewGrid()
            .backgroundColor(.black)
            .consume(text: name)
            .sizeGridToContainerNode()
        newGrid.rootNode.categoryBitMask = HitTestType.semanticTab.rawValue
        newGrid.backgroundGeometryNode.categoryBitMask = HitTestType.semanticTab.rawValue
        return newGrid
    }
    
    func allChildrenOf(_ path: FileKitPath) -> [FileKitPath] {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
    }
    
    func forEachChildOf(_ path: FileKitPath, _ receiver: (Int, FileKitPath) -> Void) {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
            .enumerated()
            .forEach(receiver)
    }
}
