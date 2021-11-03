//
//  CodeGridParser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SwiftSyntax

class CodeGridParser: SwiftSyntaxFileLoadable {

	lazy var glyphCache: GlyphLayerCache = {
        GlyphLayerCache()
    }()
	
	lazy var tokenCache: CodeGridTokenCache = {
		CodeGridTokenCache()
	}()
	
	lazy var codeGridCache: [String: CodeGrid] = {
		[:]
	}()
    
    func renderGrid(_ url: URL) -> CodeGrid? {
        guard let sourceFile = loadSourceUrl(url) else { return nil }
		let newGrid = createGrid(sourceFile)
		codeGridCache[newGrid.id] = newGrid
        return newGrid
    }
    
    private func createGrid(_ syntax: SourceFileSyntax) -> CodeGrid {
        let grid = CodeGrid(glyphCache: glyphCache,
							tokenCache: tokenCache)
            .consume(syntax: Syntax(syntax))
            .sizeGridToContainerNode()
		
        return grid
    }
}
