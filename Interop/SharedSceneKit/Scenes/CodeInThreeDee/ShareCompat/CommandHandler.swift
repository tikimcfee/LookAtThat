//
//  CodePagesController+Events.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SwiftSyntax
import Combine

protocol CommandHandler {
    var controller: CodePagesController { get }
    func handleSingleCommand(_ path: URL, _ style: FileBrowser.Event.SelectType)
}

extension CommandHandler {
    var parser: CodeGridParser { controller.codeGridParser }
    
    func renderAndCache(_ path: URL) -> CodeGrid? {
        guard let newGrid = parser.gridCache.renderGrid(path) else {
            print("No code grid we cry")
            return nil
        }
        
        // We're making duplicates of files, but cache them anyway
        // ** Clone is made for you! **
        parser.gridCache.insertGrid(newGrid)
        
        return newGrid
    }
}

struct DefaultCommandHandler: CommandHandler {
    var controller: CodePagesController
    
    func handleSingleCommand(_ path: URL, _ style: FileBrowser.Event.SelectType) {
        switch style {
        case .addToFocus:
            guard let newGrid = renderAndCache(path) else { return }
            print("Not implemented: \(#file):\(#function)")
            
        case .focusOnExistingGrid:
            guard let cachedGrid = parser.gridCache.get(path) else { return }
            print("Not implemented: \(#file):\(#function)")
            
        case .addToWorld:
            print("Not implemented: \(#file):\(#function)")
            break
        }
    }

}
