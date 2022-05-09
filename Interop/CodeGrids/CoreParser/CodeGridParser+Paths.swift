//
//  CodeGidParser+PathExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/17/22.
//

import Foundation

extension CodeGridParser {
    func allChildrenOf(_ path: FileKitPath) -> [FileKitPath] {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
    }
    
    func forEachChildOf(_ path: FileKitPath, _ receiver: (Int, FileKitPath) -> Void) {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
            .enumerated()
            .forEach(receiver)
    }
}
