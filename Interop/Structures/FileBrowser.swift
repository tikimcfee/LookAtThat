//
//  FileBrowser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/3/21.
//

import Foundation
import FileKit

class FileBrowser {
    enum Scope: Equatable, CustomStringConvertible {
        case file(Path)
        case directory(Path)
        case expandedDirectory(Path, [Scope])
        
        static func from(_ path: Path) -> Scope {
            return path.isDirectory
            ? .directory(path)
            : .file(path)
        }
        
        func typeCompare(_ l: Scope, _ r: Scope) -> Bool {
            switch (l, r) {
            case (.directory, .file),
                (.expandedDirectory, .file):
                return true
            default:
                return false
            }
        }
        
        func nameCompare(_ l: Scope, _ r: Scope) -> Bool {
            switch (l, r) {
            case let (.file(lPath), .file(rPath)),
                let (.directory(lPath), .directory(rPath)),
                let (.expandedDirectory(lPath, _), .expandedDirectory(rPath, _)):
                return lPath.rawValue <= rPath.rawValue
            default:
                return false
            }
        }
        
        var description: String {
            switch self {
            case let .file(path):
                return "file://\(path)"
            case let .directory(path):
                return "dir://\(path)"
            case let .expandedDirectory(path, scopes):
                return "\(path.components.last ?? "<missing file components>")->{\(scopes.map { $0.description }.joined(separator: ","))}"
            }
        }
    }
    
    private(set) var scopes: [Scope] = []
    
    func setRootScope(_ path: Path) {
        scopes.removeAll()
        if path.isDirectory {
            scopes.append(.directory(path))
        } else {
            scopes.append(.file(path))
        }
    }
    
    func expand(_ index: Int) {
        guard scopes.indices.contains(index) else {
            print("invalid expand index \(index) in \(scopes.indices)")
            return
        }
        
        guard case let Scope.directory(path) = scopes[index] else {
            print("scope not a directory: \(scopes[index])")
            return
        }
        
        scopes[index] = .expandedDirectory(
            path, path.children().map(Scope.from)
        )
    }
    
    func collapse(_ index: Int) {
        guard scopes.indices.contains(index) else {
            print("invalid expand index \(index) in \(scopes.indices)")
            return
        }
        
        guard case let Scope.expandedDirectory(path, _) = scopes[index] else {
            print("scope not a directory: \(scopes[index])")
            return
        }
        
        scopes[index] = .directory(path)
    }
}
