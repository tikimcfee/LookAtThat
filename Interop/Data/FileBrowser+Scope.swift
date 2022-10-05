//
//  FileBrowser+Scope.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/24/22.
//

import Foundation

extension FileBrowser.Scope: Codable { }

extension FileBrowser {
    enum Scope: Equatable, CustomStringConvertible, Identifiable {
        case file(URL)
        case directory(URL)
        case expandedDirectory(URL)
        
        var id: String { description }
        
        static func from(_ path: URL) -> Scope {
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
                return lPath.lastPathComponent <= rPath.lastPathComponent
            default:
                return false
            }
        }
        
        var path: URL {
            switch self {
            case let .file(path):
                return path
            case let .directory(path):
                return path
            case let .expandedDirectory(path):
                return path
            }
        }
        
        var description: String {
            switch self {
            case let .file(path):
                return path.path
            case let .directory(path):
                return path.path
            case let .expandedDirectory(path):
                return path.path
            }
        }
    }
}

private extension AppStatePreferences {
    func persistAsCurrentScope(_ scope: FileBrowser.Scope) {
        do {
            let scopeData = try scope.path.createDefaultBookmark()
            securedScopeData = (scope, scopeData)
        } catch {
            print("Failed to create secure url scope: ", error)
        }
    }
}

extension FileBrowser {
    var rootScope: Scope? {
        return scopes.first
    }
    
    static func distanceTo(parent: Scope, from start: Scope) -> Int {
        var matchesFromRoot = 0
        let parentComponents = parent.path.pathComponents
        let startComponents = start.path.pathComponents
        var index = parent.path.pathComponents.startIndex
        
        while parentComponents.indices.contains(index) && startComponents.indices.contains(index) {
            let matches = parentComponents[index] == startComponents[index]
            if matches { matchesFromRoot += 1 } else { break }
            index += 1
        }
        
        let componentsDifference = startComponents.count - matchesFromRoot
        return componentsDifference
    }
    
    func distanceToRoot(_ start: Scope) -> Int {
        guard let rootPath = rootScope else { return 0 }
        return Self.distanceTo(parent: rootPath, from: start)
    }
    
    func saveScope(_ scope: Scope) {
        AppStatePreferences.shared.persistAsCurrentScope(scope)
    }
    
    func loadRootScopeFromDefaults() {
        if let lastScope = AppStatePreferences.shared.securedScopeData {
            URL.doWithScopedBookmark(lastScope.1) { scopedURL in
                setRootScope(scopedURL)
            }
        }
    }
    
    func setRootScope(_ path: URL) {
        scopes.removeAll()
        if path.isDirectory {
            let expanded = Scope.expandedDirectory(path)
            scopes.append(expanded)
            expandCollapsedDirectory(rootIndex: 0, path)
            saveScope(expanded)
        } else {
            let file = Scope.file(path)
            scopes.append(file)
            saveScope(file)
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
            fileSelectionEvents = .newSingleCommand(newPathSelection, .addToFocus)
        case let .directory(path):
            scopes[index] = .expandedDirectory(path)
            expandCollapsedDirectory(rootIndex: index, path)
        case let .expandedDirectory(path):
            scopes[index] = .directory(path)
            collapseExpandedDirectory(rootIndex: index, path)
        }
    }
    
    private func expandCollapsedDirectory(rootIndex: Array.Index, _ path: URL) {
        let subpaths = path.filterdChildren(Self.isFileObserved)
        let expandedChildren = subpaths
            .reduce(into: [Scope]()) { result, path in
                result.append(Scope.from(path))
            }
        scopes.insert(contentsOf: expandedChildren, at: rootIndex + 1)
    }
    
    private func collapseExpandedDirectory(rootIndex: Array.Index, _ path: URL) {
        // Remove starting from the largest offset.
        // Stop at 1 to leave the new .directory() in place.
        // Needs to be inclusive because the count is equivalent
        // to an offset from the index already.
        
        // It gets worse. The files are flat so I have offsets to deal with.
        // Going to use a SLOW AS HELL firstWhere to get the indices and remove them.
        // Gross.
        let subpathCount = path.filterdChildren(Self.isFileObserved).count
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
}
