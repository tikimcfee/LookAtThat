import Foundation
import SceneKit
import SwiftSyntax
import Combine
import SwiftUI

class CodePagesController: ObservableObject {
        
    let codeGridParser: CodeGridParser = CodeGridParser()
    
    var fileBrowser: FileBrowser { GlobalInstances.fileBrowser }
    lazy var fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    lazy var fileEventStream = fileBrowser.$fileSelectionEvents.share().eraseToAnyPublisher()
    
    lazy var globalSemantics = CodeGridGlobalSemantics(source: codeGridParser.gridCache)
    var cancellables = Set<AnyCancellable>()

    lazy var commandHandler = DefaultCommandHandler(controller: self)

    init() {
        
    }
}

// MARK: File loading

extension CodePagesController {
    func requestSetRootDirectory() {
        #if os(OSX)
        selectDirectory { result in
            switch result {
            case .failure(let error):
                print(error)
                
            case .success(let directory):
                self.fileBrowser.setRootScope(directory.parent)
            }
        }
        #endif
    }
    
    func requestSourceFile(_ receiver: @escaping (URL) -> Void) {
        openFile { fileReslt in
            switch fileReslt {
            case let .success(url):
                receiver(url)
            case let .failure(error):
                print(error)
            }
        }
    }
}
