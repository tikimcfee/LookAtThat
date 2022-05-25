//
//  FileBrowser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/3/21.
//

import Foundation
import FileKit
import Combine

// TODO: FileKit.Path vs SwiftUI.Path
// find a better way to disambiguate
typealias FileKitPath = Path

class FileBrowser: ObservableObject {
    @Published var scopes: [Scope] = []
    @Published var fileSeletionEvents: FileBrowser.Event = .noSelection
}

extension FileBrowser {    
    // This is fragile. Both collapse/expand need to filter repeatedly.
    static func isFileObserved(_ path: Path) -> Bool {
        path.isDirectoryFile || isSwiftFile(path)
    }
    
    static func isSwiftFile(_ path: Path) -> Bool {
        path.pathExtension == "swift"
    }
    
    static func directChildren(_ path: Path) -> [Path] {
        path.children(recursive: false).filter { isFileObserved($0) }
    }
    
    static func recursivePaths(_ path: Path) -> [Path] {
        path.children(recursive: true).filter { isFileObserved($0) }
    }
    
    static func sortedFilesFirst(_ left: Path, _ right: Path) -> Bool {
        switch (left.isDirectory, right.isDirectory) {
        case (true, true): return left.url.path < right.url.path
        case (false, true): return true
        case (true, false): return false
        case (false, false): return left.url.path < right.url.path
        }
    }
}

extension Path {
    func filterdChildren(_ filter: (Path) -> Bool) -> [Path] {
        children()
            .filter(filter)
            .sorted(by: FileBrowser.sortedFilesFirst)
    }
}
