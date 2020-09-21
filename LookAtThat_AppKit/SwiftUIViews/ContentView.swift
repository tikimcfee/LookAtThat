import SwiftUI
import SceneKit

struct ContentView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global

    var body: some View {
        return ZStack(alignment: .bottomTrailing) {
            SceneKitView(sceneView: library.sharedSceneView,
                         currentScene: library.currentMode)
            switch library.currentMode {
            case .dictionary:
                VStack(spacing: 0) {
                    TestButtons_Dictionary()
                    TestButtons_Debugging()
                }
            case .source:
                HStack(alignment: .bottom) {
                    TestButtons_Debugging()
                    Spacer()
                    SourceInfoGrid()
                }
            }
        }
    }
}

struct TestButtons_Debugging: View {
    var body: some View {
        VStack() {
            Text("Debugging").padding()
            HStack {
                Button(action: toggleBoundingBoxes) {
                    Text("Toggle bounds")
                }
                Button(action: resetScene) {
                    Text("Reset scene")
                }
                Button(action: dictionaryDemo) {
                    Text("Dictionary demo")
                }
                Button(action: sourceDemo) {
                    Text("Source demo")
                }
            }
        }.padding()
    }

    private func dictionaryDemo() {
        SceneLibrary.global.dictionary()
    }

    private func sourceDemo() {
        SceneLibrary.global.codePages()
    }

    private func toggleBoundingBoxes() {
        SceneLibrary.global.currentController.toggleBoundingBoxes()
    }

    private func resetScene() {
        SceneLibrary.global.currentController.resetScene()
    }
}


public class WrappedBinding<Value> {
    private var current: Value
    init(_ start: Value) {
        self.current = start
    }
    lazy var binding = Binding<Value>(
        get: { return self.current },
        set: { (val: Value) in self.current = val }
    )
}
