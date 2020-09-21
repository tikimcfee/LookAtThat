import Foundation
import SceneKit
import SwiftUI

struct SourceInfoGrid: View {
    @State var error: SceneControllerError?
    @State var sourceInfo: SourceInfo?

    var body: some View {
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

                identifiers(named: "All Identifiers",
                            with: info.allTokens.map.map{ $0.key })
            } else {
                Text("No source info to display")
                    .padding()
            }
            buttons
        }
        .frame(width: 296, alignment: .leading)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
    }

    @ViewBuilder
    func identifiers(named: String, with names: [String]) -> some View {
        Text(named).underline().padding(.top, 8)
        List {
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
            }
        }.frame(minHeight: 128)
    }

    func grid(for stringSlices: [ArraySlice<String>]) -> some View {
        return List {
            ForEach(0..<stringSlices.count, id:\.self) { row in
                HStack {
                    ForEach(0..<stringSlices[row].count, id:\.self) { column in
                        Button(action: {
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
        SceneLibrary.global.codePagesController.selected(name: name)
    }

    var buttons: some View {
        return VStack {
            HStack {
               Button(action: renderSource) {
                   Text("Load source")
               }
               Spacer()
               Button(action: renderDirectory) {
                   Text("Load directory")
               }
           }
        }
    }

    private func renderSource() {
        SceneLibrary.global.codePagesController.renderSyntax{ info in
            sourceInfo = info
        }
    }

    private func renderDirectory() {
        SceneLibrary.global.codePagesController.renderDirectory{ info in
            sourceInfo = info
        }
    }
}

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
            self.error = error as? SceneControllerError
        }
    }
}

#if DEBUG
import SwiftSyntax
struct SourceInfo_Previews: PreviewProvider {
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
        SourceInfoGrid(sourceInfo: Self.sourceInfo.binding.wrappedValue)
    }
}
#endif
