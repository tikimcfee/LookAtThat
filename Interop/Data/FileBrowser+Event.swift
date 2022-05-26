//
//  FileBrowser+Event.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/24/22.
//

import Foundation

extension FileBrowser {
    enum Event {
        enum SelectType {
            case addToFocus
            case addToWorld
            case focusOnExistingGrid
        }
        
        case noSelection
        
        case newSingleCommand(URL, SelectType)
        
        case newMultiCommandRecursiveAllCache(URL)
        case newMultiCommandRecursiveAllLayout(URL, SelectType)
    }
}
