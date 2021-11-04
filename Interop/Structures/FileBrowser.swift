//
//  FileBrowser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/3/21.
//

import Foundation
import FileKit
import Combine

class FileBrowser: ObservableObject {
    @Published private(set) var scopes: [Scope] = []
    
    enum Scope: Equatable, CustomStringConvertible, Identifiable {
        case file(Path)
        case directory(Path)
        case expandedDirectory(Path)
        
        var id: String { description }
        
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
                let (.expandedDirectory(lPath), .expandedDirectory(rPath)):
                return lPath.rawValue <= rPath.rawValue
            default:
                return false
            }
        }
        
        var description: String {
            switch self {
            case let .file(path):
                return path.absolute.rawValue
            case let .directory(path):
                return path.absolute.rawValue
            case let .expandedDirectory(path):
                return path.absolute.rawValue
            }
        }
    }
}

extension FileBrowser {
    func setRootScope(_ path: Path) {
        scopes.removeAll()
        if path.isDirectory {
            scopes.append(.directory(path))
        } else {
            scopes.append(.file(path))
        }
    }
    
    func onScopeSelected(_ scope: Scope) {
        guard let index = scopes.firstIndex(of: scope) else {
            print("invalid select scope \(scope) in \(scopes)")
            return
        }
        
        switch scopes[index] {
        case let .file(path):
            // on file selected; call render()
            break
        case let .directory(path):
            let expandedChildren = path.children().map(Scope.from)
            scopes[index] = .expandedDirectory(path)
            scopes.insert(contentsOf: expandedChildren, at: index + 1)
        case let .expandedDirectory(path):
            scopes[index] = .directory(path)
            // Remove starting from the largest offset.
            // Stop at 1 to leave the new .directory() in place.
            // Needs to be inclusive because the count is equivalent
            // to an offset from the index already.
            
            // It gets worse. The files are flat so I have offsets to deal with.
            // Going to use a SLOW AS HELL firstWhere to get the indices and remove them.
            // Gross.
            (1...path.children().count).reversed().forEach { offset in
                let removeIndex = index + offset
                let removeScope = scopes[removeIndex]
                if case .expandedDirectory = removeScope {
                    onScopeSelected(removeScope)
                }
                scopes.remove(at: removeIndex)
            }
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
        
        scopes[index] = .expandedDirectory(path)
    }
    
    func collapse(_ index: Int) {
        guard scopes.indices.contains(index) else {
            print("invalid collapse index \(index) in \(scopes.indices)")
            return
        }

        guard case let Scope.expandedDirectory(path) = scopes[index] else {
            print("scope not an expanded directory: \(scopes[index])")
            return
        }
        
        scopes[index] = .directory(path)
    }
}
