//
//  FileBrowser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/3/21.
//

import Foundation
import Combine

class FileBrowser: ObservableObject {
    @Published var scopes: [Scope] = []
    @Published var fileSeletionEvents: FileBrowser.Event = .noSelection
}

extension FileBrowser {    
    // This is fragile. Both collapse/expand need to filter repeatedly.
    static func isFileObserved(_ path: Path) -> Bool {
        path.isDirectory || isSwiftFile(path)
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
        case (true, true): return left.path < right.path
        case (false, true): return true
        case (true, false): return false
        case (false, false): return left.path < right.path
        }
    }
}


typealias Path = URL
typealias FileKitPath = URL

extension URL {
    // This is gross, but the scope must remain open for the duration of usage
    // since we actively read from arbitrary paths in the tree. Track to at least
    // have a record and descope if needed.
    private static var openScopedBookmarks = Set<URL>()
    private static func newOpenScope(_ url: URL) {
        if openScopedBookmarks.contains(url) {
            print("Warning, set already contains this url!")
        }
        openScopedBookmarks.insert(url)
        print("Scoped URL recorded: \(url)")
    }
    static func dumpAndDescopeAllKnownBookmarks() {
        openScopedBookmarks.forEach {
            print("Descoping: \($0)")
            $0.stopAccessingSecurityScopedResource()
        }
        openScopedBookmarks = []
    }
    
    static func doWithScopedBookmark(
        _ data: Data,
        _ receiver: (URL) -> Void
    ) {
        do {
            var isStale = false
            let scopedBookmarkURL = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                print("Stale bookmark found, must recreate")
            }
            guard scopedBookmarkURL.startAccessingSecurityScopedResource() else {
                print("Could not access security scope at \(self)")
                return
            }
            receiver(scopedBookmarkURL)
            newOpenScope(scopedBookmarkURL)
        } catch {
            print(error)
        }
    }
}

extension Path {
    private static let _fileManager = FileManager.default
    private var fileManager: FileManager { Self._fileManager }
    
    var isDirectory: Bool { hasDirectoryPath }
    var isDirectoryFile: Bool { isFileURL }
    var fileName: String { lastPathComponent }
    
    func children(recursive: Bool = false) -> [Path] {
        let obtainFunc = recursive
        ? fileManager.subpathsOfDirectory(atPath:)
        : fileManager.contentsOfDirectory(atPath:)
        
        do {
            let found = try obtainFunc(path)
            return found.map { pathComponent in
                appendingPathComponent(pathComponent)
            }
        } catch {
            print("Failed to iterate children, recursive=\(recursive): ", error)
            return []
        }
    }
    
    func filterdChildren(_ filter: (Path) -> Bool) -> [Path] {
        children()
            .filter(filter)
            .sorted(by: FileBrowser.sortedFilesFirst)
    }
}
