//
//  CodeGridParser+WorldExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/17/22.
//

import Foundation

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
}
