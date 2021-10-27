import Foundation
import SceneKit
import SwiftUI

struct SourceInfoGrid: View {
    @State var error: SceneControllerError?
	@State var sourceInfo: CodeGridAssociations = CodeGridAssociations() 

    var body: some View {
        return VStack(alignment: .leading) {
			VStack {
				infoRows(named: "Structs", from: sourceInfo.structs)
				infoRows(named: "Classes", from: sourceInfo.classes)
				infoRows(named: "Enumerations", from: sourceInfo.enumerations)
				infoRows(named: "Extensions", from: sourceInfo.extensions)
				infoRows(named: "Functions", from: sourceInfo.functions)
				infoRows(named: "Variables", from: sourceInfo.variables)
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
        .onReceive(
            SceneLibrary.global.codePagesController.sheetStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { selectedSheet in
//            self.sourceInfo = selectedSheet?.sourceInfo
        }
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
        }.frame(minHeight: 64)
    }

    @ViewBuilder
    func infoRows(named: String, from pair: GridCollection) -> some View {
        Text(named).underline().padding(.top, 8)
        List {
			ForEach(Array(pair.keys), id:\.self) { id in
                VStack {
					if let rowName = sourceInfo.textCache[id] {
                        Text(rowName)
                            .frame(minWidth: 232, alignment: .leading)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray)
                            )
                            .onTapGesture {
                                selected(id: id)
                            }
                    } else {
                        Text("No SemanticInfo")
                    }
                }
            }
        }.frame(minHeight: 64)
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

    func selected(id: SyntaxIdentifier) {
        SceneLibrary.global.codePagesController.selected(id: id, in: sourceInfo)
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
        SceneLibrary.global.codePagesController.renderDirectory{ states in
//            sourceInfo = states.first?.organizedSourceInfo
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
            print(error)
            self.error = error as? SceneControllerError
        }
    }
}

#if DEBUG
import SwiftSyntax
struct SourceInfo_Previews: PreviewProvider {
    static var sourceInfo = WrappedBinding<CodeGridAssociations>(
        {
            let info = CodeGridAssociations()
            return info
        }()
    )

    static var previews: some View {
        SourceInfoGrid(sourceInfo: Self.sourceInfo.binding.wrappedValue)
    }
}
#endif
