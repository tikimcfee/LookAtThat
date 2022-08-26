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
        CodeGrid()
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
    
    func makeFileNameGrid(_ name: String) -> CodeGrid {
        let newGrid = createNewGrid()
            .consume(text: name)
        return newGrid
    }
}
