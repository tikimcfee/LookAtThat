//
//  FileBrowser+Event.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/24/22.
//

import Foundation
import FileKit

extension FileBrowser {
    enum Event {
        enum SelectType {
            case addToFocus
            case addToWorld
            case focusOnExistingGrid
        }
        
        case noSelection
        
        case newSingleCommand(Path, SelectType)
        
        case newMultiCommandRecursiveAllCache(Path)
        case newMultiCommandRecursiveAllLayout(Path, SelectType)
    }
}
