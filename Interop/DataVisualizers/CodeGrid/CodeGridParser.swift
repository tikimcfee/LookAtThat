//
//  CodeGridParser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

class CodeGridParser: SwiftSyntaxFileLoadable {

	lazy var glyphCache: GlyphLayerCache = {
        GlyphLayerCache()
    }()
	
	lazy var tokenCache: CodeGridTokenCache = {
		CodeGridTokenCache()
	}()
    
    let plane = CodeGridPlane()
    
    func renderGrid(_ url: URL) -> CodeGrid? {
        guard let sourceFile = loadSourceUrl(url) else { return nil }
		let newGrid = createGrid(sourceFile)
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

struct Plane {
    private var x: Int = 0
    private var y: Int = 0
    private var z: Int = 0
    
    private var cache: [
        [
            [CodeGrid]
        ]
    ] = [[[]]]
    
    private var lastPlane: [
        [CodeGrid]
    ] {
        guard cache.indices.contains(z) else {
            fatalError("bad depth access: \(z)")
        }
        
        let forwardPlane = cache[z]
        return forwardPlane
    }
    
    private var lastRow: [CodeGrid] {
        let forwardPlane = lastPlane
        guard forwardPlane.indices.contains(y) else {
            fatalError("bad plane access: \(y)")
        }
        
        let fowardPlaneRow = forwardPlane[y]
        return fowardPlaneRow
    }
    
    private var lastGrid: CodeGrid {
        let forwardRow = lastRow
        guard forwardRow.indices.contains(x) else {
            fatalError("bad row access: \(x)")
        }
        
        let lastFrid = forwardRow[x]
        return lastFrid
    }
}

class CodeGridPlane {
    var rootContainerNode: SCNNode = SCNNode()
    
    private let default_gridWidth = 3
    
    private var depthIndex = 0
    private var columnIndex = 0
    private var rowIndex = 0
    
    private var lastIndex: (Int, Int, Int) = (0, 0, 0)
    
    private var plane: [
        [
            [CodeGrid]
        ]
    ] = [[[]]]
    
    var gridCache: [CodeGrid] = []
    
    var lastGrid: CodeGrid?
    
    func addGrid(_ newGrid: CodeGrid) {
        
        var isNewLine = false
        if columnIndex >= default_gridWidth {
            columnIndex = 0
            rowIndex += 1
            isNewLine.toggle()
        }
        
        let lastGrid = gridAt(row: rowIndex, col: -1 + columnIndex)
        let lastRowFirstGrid = gridAt(row: rowIndex - 1, col: 0)
        
        let lastGridPosition = !isNewLine
            ? lastGrid?.rootNode.position ?? SCNVector3Zero
            : lastRowFirstGrid?.rootNode.position ?? SCNVector3Zero
        
        let rightmost = !isNewLine
            ? lastGridPosition.translated(dX: (lastGrid?.rootNode.lengthX ?? 0) + 8.0)
            : lastGridPosition.translated(dY: -((lastRowFirstGrid?.rootNode.lengthY ?? 0) + 8.0))
        
        newGrid.rootNode.position.x = rightmost.x
        newGrid.rootNode.position.y = rightmost.y
        newGrid.rootNode.position.z = rightmost.z
        rootContainerNode.addChildNode(newGrid.rootNode)
        
        columnIndex += 1
        gridCache.append(newGrid)
    }
    
    private func gridAt(row: Int, col: Int, _ depth: Int = 0) -> CodeGrid? {
        let index = (row * default_gridWidth) + col
        guard gridCache.indices.contains(index) else { return nil }
        return gridCache[index]
    }
    
    enum Style {
        case stackBehindLast
        case trailingFromLast
        case LeadingFromLast
    }
}
