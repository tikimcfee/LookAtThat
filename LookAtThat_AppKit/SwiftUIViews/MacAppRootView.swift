import SwiftUI
import SceneKit

struct MacAppRootView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global

    var body: some View {
        return ZStack(alignment: .bottomTrailing) {
            SceneKitRepresentableView(
                sceneView: library.sharedSceneView
            )
            
            switch library.currentMode {
            case .dictionary:
                VStack(spacing: 0) {
                    TestButtons_Dictionary()
                    TestButtons_Debugging()
                }.padding(.bottom, 16.0)
            case .source:
                VStack {
                    HStack(alignment: .bottom) {
                        //                    MultipeerInfoView()
                        //                        .frame(maxHeight: 512.0)
                        SourceInfoGrid()
                    }.padding(.bottom, 16.0)
                    TestButtons_Debugging()
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
