import Foundation
import SceneKit
import Combine

class SceneLibrary: ObservableObject {
    static var global: SceneLibrary = SceneLibrary()
    
    let codePagesController: CodePagesController

    var cancellables = Set<AnyCancellable>()
    let input = DefaultInputReceiver()

    private init() {
        self.codePagesController = CodePagesController()
    }
}

class GlobalInstances {
    // MARK: - Files
    static let fileBrowser = FileBrowser()
    static let fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    static let fileEventStream = fileBrowser.$fileSelectionEvents.share().eraseToAnyPublisher()
    
    // MARK: - Metal
    // TODO: I'm just moving globals around lolz
    static let rootCustomMTKView: CustomMTKView = {
        CustomMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }()
    static let defaultLink: MetalLink = {
        return try! MetalLink(view: rootCustomMTKView)
    }()
    static let defaultAtlas: MetalLinkAtlas = {
        return try! MetalLinkAtlas(defaultLink)
    }()
    
    // MARK: - App State
    static let appStatus = AppStatus()
    static let editorState = CodePagesPopupEditorState()
}
