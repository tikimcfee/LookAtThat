import Foundation

import AppKit


typealias FileResult = Result<URL, FileError>
typealias FileReceiver = (FileResult) -> Void

typealias DirectoryResult = Result<Directory, FileError>
typealias DirectoryReceiver = (DirectoryResult) -> Void

struct Directory {
    let swiftUrls: [URL]
}

enum FileError: Error {
    case generic
    case noSwiftSource
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

            receiver(.success((Directory(swiftUrls: swiftFiles))))
        }
    }
}
