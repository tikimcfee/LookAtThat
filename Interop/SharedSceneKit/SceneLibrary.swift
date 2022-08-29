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
