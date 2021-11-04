import Foundation

#if os(OSX)
import AppKit
#endif


typealias FileResult = Result<URL, FileError>
typealias FileReceiver = (FileResult) -> Void

typealias DirectoryResult = Result<Directory, FileError>
typealias DirectoryReceiver = (DirectoryResult) -> Void

struct Directory {
    let parent: URL
    let swiftUrls: [URL]
}

enum FileError: Error {
    case generic
    case noSwiftSource
}

#if os(OSX)
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

func fileKitTests() {
    selectDirectory { result in
        switch result {
        case .failure(let error):
            print(error)
            
        case .success(let directory):
            let path: Path = Path(directory.parent.path)
            let browser = FileBrowser()
            browser.setRootScope(path)
            print(browser.scopes)
            print("\n----\n")
            browser.expand(0)
            print(browser.scopes)
        }
    }
}

func openFile(_ receiver: @escaping FileReceiver) {
    DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.nameFieldLabel = "Choose a Swift source file to view"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canHide = true
        panel.begin { response in
            guard response == NSApplication.ModalResponse.OK,
                let fileUrl = panel.url else {
                receiver(.failure(.generic))
                return
            }
            receiver(.success(fileUrl))
        }
    }
}

func selectDirectory(_ receiver: @escaping DirectoryReceiver) {
    DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.nameFieldLabel = "Select source directory"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canHide = true
        panel.begin { response in
            guard response == NSApplication.ModalResponse.OK,
                  let directoryUrl = panel.url else {
                      receiver(.failure(.generic))
                      return
                  }
            
            receiver(.success(
                Directory(
                    parent: directoryUrl,
                    swiftUrls: [] // lame. Should just be a URL or.. something else.
                ))
            )
        }
    }
}


func openDirectory(_ receiver: @escaping DirectoryReceiver) {
    DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.nameFieldLabel = "Choose a directory to load all .swift files"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canHide = true
        panel.begin { response in
            guard response == NSApplication.ModalResponse.OK,
                  let directoryUrl = panel.url else {
                receiver(.failure(.generic))
                return
            }

            let contents = try? FileManager.default.contentsOfDirectory(
                at: directoryUrl,
                includingPropertiesForKeys: nil,
                options: .skipsSubdirectoryDescendants
            )

            guard let swiftFiles = contents?.filter({ $0.pathExtension == "swift" }),
                swiftFiles.count > 0 else {
                receiver(.failure(.noSwiftSource))
                return
            }

            receiver(.success(
                Directory(
                    parent: directoryUrl,
                    swiftUrls: swiftFiles
                ))
            )
        }
    }
}
#elseif os(iOS)
func openFile(_ receiver: @escaping FileReceiver) {
    print("Open file not implemented", #file)
}

func openDirectory(_ receiver: @escaping DirectoryReceiver) {
    print("Open directory not implemented", #file)
}
#endif
