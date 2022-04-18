//
//  CodeGridParser+Rendering.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/17/22.
//

import Foundation

extension CodeGridParser {
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
