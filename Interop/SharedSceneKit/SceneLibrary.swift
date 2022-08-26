import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
}

class SceneLibrary: ObservableObject   {
    public static let global = SceneLibrary()

    let codePagesController: CodePagesController
    
    @Published var currentMode: SceneType
    var cancellables = Set<AnyCancellable>()
    let input = DefaultInputReceiver()

    private init() {
        self.codePagesController = CodePagesController()

        // Unsafe initialization from .global ... more refactoring inc?
        self.currentMode = .source
    }
}
