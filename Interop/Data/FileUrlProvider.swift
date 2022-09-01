import Foundation

#if os(OSX)
import AppKit
#endif


typealias FileResult = Result<URL, FileError>
typealias FileReceiver = (FileResult) -> Void

typealias DirectoryResult = Result<Directory, FileError>
typealias DirectoryReceiver = (DirectoryResult) -> Void

extension DirectoryResult {
    var parent: URL? {
        if case let .success(url) = self { return url.parent }
        return nil
    }
    var children: [URL]? {
        if case let .success(url) = self { return url.swiftUrls }
        return nil
    }
}

struct Directory {
    let parent: URL
    let swiftUrls: [URL]
}

enum FileError: Error {
    case generic
    case noSwiftSource
}

func showInFinder(url: URL?) {
    switch url {
#if os(OSX)
    case let .some(url) where url.isDirectory:
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    case let .some(url):
        NSWorkspace.shared.activateFileViewerSelecting([url])
#endif
    default:
        print("Cannot open url: \(url?.description ?? "<nil url>")")
    }
}

#if os(OSX)

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

func selectDirectory(
    _ config: ((NSOpenPanel) -> Void)? = nil,
    _ receiver: @escaping DirectoryReceiver
) {
    DispatchQueue.main.async {
        let panel = NSOpenPanel()
        config?(panel)
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

            let swiftFiles = try? FileManager.default.contentsOfDirectory(
                at: directoryUrl,
                includingPropertiesForKeys: nil,
                options: .skipsSubdirectoryDescendants
            ).filter({ $0.pathExtension == "swift" })

            receiver(.success(
                Directory(
                    parent: directoryUrl,
                    swiftUrls: swiftFiles ?? []
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
