//
//  CodeGidParser+PathExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/17/22.
//

import Foundation

extension CodeGridParser {
    func allChildrenOf(_ path: URL) -> [URL] {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
    }
    
    func forEachChildOf(_ path: URL, _ receiver: (Int, URL) -> Void) {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
            .enumerated()
            .forEach(receiver)
    }
}
