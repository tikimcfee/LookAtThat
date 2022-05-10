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

extension CodeGridParser {
    func createNewGrid() -> CodeGrid {
        CodeGrid(
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
    }
    
    func createGridFromSyntax(_ syntax: SourceFileSyntax, _ sourceURL: URL?) -> CodeGrid {
        let grid = createNewGrid()
            .consume(rootSyntaxNode: Syntax(syntax))
            .sizeGridToContainerNode()
            .applying {
                if let url = sourceURL, let path = FileKitPath(url: url) {
                    $0.withFileName(path.fileName)
                      .withSourcePath(path)
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
}
