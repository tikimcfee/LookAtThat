import SwiftUI
import SceneKit

var DRAG_GESTURE_LAST_POINT: CGPoint?

enum DemoMode {
    case dictionary
    case source
}

struct ContentView: View {

    @State var currentInput = ""
    @State var error: SceneControllerError?
    @State var demoMode: DemoMode = .source
    @State var sourceInfo: SourceInfo?

    var body: some View {
        return ZStack {
            HStack {
                VStack {
                    SceneKitView(sceneController: MainSceneController.global)
                    buttons
                }.padding()
                VStack(alignment: .leading) {
                    SourceInfoGrid(sourceInfo: $sourceInfo)
                }
            }
        }
    }


    var buttons: some View {
        VStack {
            switch demoMode {
            case .dictionary:
                TestButtons_Dictionary(error: $error,
                                       currentInput: $currentInput)
            case .source:
                TestButtons_Source(error: $error,
                                   currentInput: $currentInput,
                                   sourceInfo: $sourceInfo)
            }
            TestButtons_Debugging(demoMode: $demoMode)
        }
    }
}

struct SourceInfoGrid: View {
    @Binding var sourceInfo: SourceInfo?

    var body: some View {
//        let stringSlices =
//            Array(info.strings).sorted()
//                .slices(sliceSize: 5)
//
//        let identifierSlices =
//            Array(info.identifiers).sorted()
//                .slices(sliceSize: 5)
        return VStack(alignment: .leading) {
            if let info = sourceInfo {
                identifiers(named: "Function Declarations",
                            with: info.functions.map.map{ $0.key })

                identifiers(named: "Enum Declarations",
                            with: info.enums.map.map{ $0.key })

                identifiers(named: "Closures",
                            with: info.closures.map.map{ $0.key })

                identifiers(named: "Extensions",
                            with: info.extensions.map.map{ $0.key })
            }
//                grid(for: stringSlices).frame(height: 256)
//                grid(for: identifierSlices).frame(height: 256)
        }
        .padding(8)
        .frame(width: 256, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }

    @ViewBuilder
    func identifiers(named: String, with names: [String]) -> some View {
        Text(named).underline().padding(.top, 8)
        ForEach(names, id:\.self) { name in
            Text(name)
                .frame(minWidth: 232, alignment: .leading)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray)
                )
                .onTapGesture {
                    selected(name: name)
                }
                .padding(.vertical, 4)
        }
    }

    func grid(for stringSlices: [ArraySlice<String>]) -> some View {
        return List {
            ForEach(0..<stringSlices.count, id:\.self) { row in
                HStack {
                    ForEach(0..<stringSlices[row].count, id:\.self) { column in
                        return Button(action: {
                            selected(name: Array(stringSlices[row])[column])
                        }) {
                            Text("\(Array(stringSlices[row])[column])")
                                .lineLimit(0)
                        }.padding(0)
                        .frame(width: 44, height: 44, alignment: .center)
                    }
                }
            }
        }
    }

    func selected(name: String) {
        MainSceneController.global.selected(name: name)
    }
}

struct TestButtons_Debugging: View {
    @Binding var demoMode: DemoMode
    var body: some View {
        VStack {
            Text("Debugging")
            HStack {
                Button(action: toggleBoundingBoxes) {
                    Text("Toggle bounds")
                }
                Button(action: resetScene) {
                    Text("Reset scene")
                }
                Button(action: { demoMode = .dictionary }) {
                    Text("Dictionary demo")
                }
                Button(action: { demoMode = .source }) {
                    Text("Source demo")
                }
            }
        }
    }

    private func toggleBoundingBoxes() {
        MainSceneController.global.toggleBoundingBoxes()
    }

    private func resetScene() {
        MainSceneController.global.resetScene()
    }
}

struct TestButtons_Source: View {
    @Binding var error: SceneControllerError?
    @Binding var currentInput: String
    @Binding var sourceInfo: SourceInfo?

    var body: some View {
        return HStack {
            TextField(
                "...",
                text: $currentInput
            ).focusable()
            Button(action: renderSource) {
                Text("Load source")
            }
            Button(action: renderDirectory) {
                Text("Load directory")
            }
        }
    }

    private func renderSource() {
        MainSceneController.global.renderSyntax { info in
            sourceInfo = info
        }
    }

    private func renderDirectory() {
        MainSceneController.global.renderDirectory { info in
            sourceInfo = info
        }
    }
}

struct TestButtons_Dictionary: View {
    @Binding var error: SceneControllerError?
    @Binding var currentInput: String
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
        MainSceneController.global.trackWordWithCamera(currentInput)
    }

    private func renderTest() {
        MainSceneController.global.renderDictionaryTest()
    }

    private func addWord() {
        guard currentInput.count > 0 else { return }
        do {
            try MainSceneController.global.add(word: currentInput)
        } catch {
            self.error = error as? SceneControllerError
        }
    }
}

#if DEBUG
import SwiftSyntax
struct ContentView_Previews: PreviewProvider {
    static var sourceInfo = WrappedBinding<SourceInfo?>(
        {
            let info = SourceInfo()
            info.functions["append"].append(FunctionDeclSyntax.init({ _ in }))
            info.functions["slice"].append(FunctionDeclSyntax.init({ _ in }))
            info.functions["add"].append(FunctionDeclSyntax.init({ _ in }))
            info.functions["multiple"].append(FunctionDeclSyntax.init({ _ in }))

            return info
        }()
    )

    static var previews: some View {
        SourceInfoGrid(sourceInfo: sourceInfo.binding)
    }
}
#endif

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
