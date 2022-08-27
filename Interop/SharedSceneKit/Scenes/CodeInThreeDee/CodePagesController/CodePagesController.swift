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

extension Set where Element == SyntaxIdentifier {
    mutating func toggle(_ id: SyntaxIdentifier) -> Bool {
        if contains(id) {
            remove(id)
            return false
        } else {
            insert(id)
            return true
        }
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

// MARK: - File Events

extension CodePagesController {
    func onNewFileStreamEvent(_ event: FileBrowser.Event) {
        switch event {
        case .noSelection:
            break
            
        case let .newSingleCommand(path, style):
            commandHandler.handleSingleCommand(path, style)
            
        case let .newMultiCommandRecursiveAllLayout(parent, style):
            switch style {
            case .addToFocus:
                print("Not implemented: \(#file):\(#function)")
                break
                
            case .addToWorld:
                doTestRender(parent: parent)
                
            default: break
            }
            
            
        case let .newMultiCommandRecursiveAllCache(parent):
            print("Start cache: \(parent.fileName)")
            print("Not implemented: \(#file):\(#function)")
        }
    }
}

extension CodePagesController {
    func doTestRender(parent: URL) {
//        codeGridParser.__versionThree_RenderConcurrent(parent) { rootGrid in
//            self.addToRoot(rootGrid: rootGrid)
//        }
        
        // TODO: Don't render both paths when doing SCENE / Metal
//        doRenderPlan(parent: parent)
    }
    
    func doRenderPlan(parent: URL) {
        RenderPlan(
            rootPath: parent,
            queue: codeGridParser.renderQueue,
            renderer: codeGridParser.concurrency
        ).startRender()
    }
}
