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
    @Published private(set) var scopes: [Scope] = []
    @Published private(set) var pathDepths: [FileKitPath: Int] = [:]
    @Published var fileSeletionEvents: FileBrowser.Event = .noSelection
    
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
    enum Event {
        enum SelectType {
            case addToRow
            case inNewRow
            case inNewPlane
            
            case allChildrenInRow
        }
        
        case noSelection
        
        case newSinglePath(Path)
        case newSingleCommand(Path, SelectType)
        
        case newMultiCommandImmediateChildren(Path, SelectType)
    }
    
    func setRootScope(_ path: Path) {
        scopes.removeAll()
        pathDepths.removeAll()
        setPathDepth(path)
        if path.isDirectory {
            scopes.append(.expandedDirectory(path))
            expandCollapsedDirectory(rootIndex: 0, path)
        } else {
            scopes.append(.file(path))
        }
    }
    
    func onScopeSelected(_ scope: Scope) {
        /* This is a bit gross in terms of side effects, but the idea is that it toggles or selects.
         
         When a 'Scope' (a file) is selected, it has a direct UI interaction associated. If selecting a file scope,
         something should be emitted stating as much.
         
         If it's a `.directory`, I know the user has selected something to 'expand' - that's the assumption.
         So, we switch the instance to `expanded` at that path, and then just add the subpaths as direct linear children.
         --> NOTE! This is EXTREMELY fragile if we start working with sorting this. The idea is just to explore files in a standard hierarchy to get something working
         If already expanded, we switch it back to `directory` and remove the children from the same root paths. That's the dangerous part. Ideally, we'd track what paths
         produced what files, but uh.. I was a little not sobre and tired and the sun was in my eyes and such.
         */
        
        guard let index = scopes.firstIndex(of: scope) else {
            print("invalid select scope \(scope) in \(scopes)")
            return
        }
        
        switch scopes[index] {
        case let .file(newPathSelection):
            fileSeletionEvents = .newSinglePath(newPathSelection)
        case let .directory(path):
            scopes[index] = .expandedDirectory(path)
            expandCollapsedDirectory(rootIndex: index, path)
        case let .expandedDirectory(path):
            scopes[index] = .directory(path)
            collapseExpandedDirectory(rootIndex: index, path)
        }
    }
    
    private func setPathDepth(_ path: Path) {
        guard pathDepths[path] == nil else { return }
        
        if let parentDepth = pathDepths[path.parent] {
            pathDepths[path] = parentDepth + 1
        } else {
            pathDepths[path] = 0
        }
    }
    
    private func expandCollapsedDirectory(rootIndex: Array.Index, _ path: Path) {
        let subpaths = path.filterdChildren(isFileObserved)
        let expandedChildren = subpaths
            .reduce(into: [Scope]()) { result, path in
                setPathDepth(path)
                result.append(Scope.from(path))
            }
        scopes.insert(contentsOf: expandedChildren, at: rootIndex + 1)
    }
    
    private func collapseExpandedDirectory(rootIndex: Array.Index, _ path: Path) {
        // Remove starting from the largest offset.
        // Stop at 1 to leave the new .directory() in place.
        // Needs to be inclusive because the count is equivalent
        // to an offset from the index already.
        
        // It gets worse. The files are flat so I have offsets to deal with.
        // Going to use a SLOW AS HELL firstWhere to get the indices and remove them.
        // Gross.
        let subpathCount = path.filterdChildren(isFileObserved).count
        guard subpathCount >= 1 else { return }
        let subpathRange = (1...subpathCount).reversed()
        subpathRange.forEach { offset in
            let removeIndex = rootIndex + offset
            let removeScope = scopes[removeIndex]
            if case .expandedDirectory = removeScope {
                onScopeSelected(removeScope)
            }
            scopes.remove(at: removeIndex)
        }
    }
    
    // This is fragile. Both collapse/expand need to filter repeatedly.
    func isFileObserved(_ path: Path) -> Bool {
        return path.isDirectoryFile || path.pathExtension == "swift"
    }
}

private extension Path {
    func filterdChildren(_ filter: (Path) -> Bool) -> [Path] {
        children().filter(filter)
    }
}
