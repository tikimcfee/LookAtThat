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
    
    QuickLooper(loop: {
        print("Looping")
    })
}
#endif
