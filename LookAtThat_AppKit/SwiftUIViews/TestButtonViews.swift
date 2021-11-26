import Foundation
import SceneKit
import SwiftUI
import FileKit
import SwiftSyntax

struct TestButtons_Dictionary: View {
    @State var error: SceneControllerError?
    @State var currentInput: String = ""
    
    var body: some View {
        return HStack {
            TextField(
                "Enter a word here (caps count)",
                text: $currentInput
            ).focusable()
            Button(action: followWord) {
                Text("Follow entry")
            }
            Button(action: addWord) {
                Text("Lookup and add")
            }
            Button(action: renderTest) {
                Text("Render dictionary")
            }
        }
    }

    private func followWord() {
        SceneLibrary.global.dictionaryController.trackWordWithCamera(currentInput)
    }

    private func renderTest() {
        SceneLibrary.global.dictionaryController.renderDictionaryTest()
    }

    private func addWord() {
        guard currentInput.count > 0 else { return }
        do {
            try SceneLibrary.global.dictionaryController.add(word: currentInput)
        } catch {
            print(error)
            self.error = error as? SceneControllerError
        }
    }
}
