//
//  CodePagesController+Events.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit
import SwiftSyntax
import Combine

protocol CommandHandler {
    var controller: CodePagesController { get }
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType)
}

extension CommandHandler {
    var parser: CodeGridParser { controller.codeGridParser }
    
    func renderAndCache(_ path: FileKitPath) -> CodeGrid? {
        guard let newGrid = parser.renderGrid(path) else {
            print("No code grid we cry")
            return nil
        }
        
        // We're making duplicates of files, but cache them anyway
        // ** Clone is made for you! **
        parser.gridCache.insertGrid(newGrid)
        
        return newGrid
    }
}
