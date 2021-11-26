import Foundation
import SceneKit
import SwiftUI
import FileKit
import SwiftSyntax

struct SourceInfoGrid: View {
    @State var error: SceneControllerError?
	
	@State var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap() 
	@State var hoveredToken: String?
    
    typealias RowType = [FileBrowser.Scope]
    @State var files: RowType = []
    @State var pathDepths: [FileKitPath: Int] = [:]

    var body: some View {
        return VStack(alignment: .leading) {
            buttons
            HStack(alignment: .top) {
                fileRows(files)
                Spacer()
                semanticInfo()
            }
        }
        .frame(alignment: .trailing)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
        .onReceive(
            SceneLibrary.global.codePagesController.fileStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { scopes in
            self.files = scopes
        }
        .onReceive(
            SceneLibrary.global.codePagesController.hoverStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { hoveredToken in
			self.hoveredToken = hoveredToken
        }
        .onReceive(
            SceneLibrary.global.codePagesController.pathDepthStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { depths in
            self.pathDepths = depths
        }
        .onReceive(
            SceneLibrary.global.codePagesController.parsedFileStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { eventTuple in
            switch (eventTuple.0, eventTuple.1) {
            case (_, .some(let grid)):
                self.sourceInfo = grid.codeGridSemanticInfo
            default:
                break
            }
        }
    }
    
    
    func fileRows(_ rows: RowType) -> some View {
        ScrollView {
            ForEach(rows, id: \.id) { scope in
                rowForScope(scope)
            }
        }
        .padding(4.0)
        .frame(
            minWidth: 256.0,
            maxWidth: 384.0,
            maxHeight: 1024.0,
            alignment: .leading
        )
        .border(.black, width: 2.0)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
    }
    
    @ViewBuilder
    func semanticInfo() -> some View {
        VStack {
            if !sourceInfo.structs.isEmpty {
                infoRows(named: "Structs", from: sourceInfo.structs)
            }

            if !sourceInfo.classes.isEmpty {
                infoRows(named: "Classes", from: sourceInfo.classes)
            }

            if !sourceInfo.enumerations.isEmpty {
                infoRows(named: "Enumerations", from: sourceInfo.enumerations)
            }

            if !sourceInfo.extensions.isEmpty {
                infoRows(named: "Extensions", from: sourceInfo.extensions)
            }

            if !sourceInfo.functions.isEmpty {
                infoRows(named: "Functions", from: sourceInfo.functions)
            }

            if !sourceInfo.variables.isEmpty {
                infoRows(named: "Variables", from: sourceInfo.variables)
            }

            hoverInfo(hoveredToken)
                .frame(width: 256, height: 256)
        }
    }
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("􀥨")
                    .font(.footnote)
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.light)
                
                Spacer()
                
                Text("􀣘")
                    .padding(4.0)
                    .font(.footnote)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .onTapGesture { fileSelected(path, .addToRow) }
                
                Text("􀄴")
                    .padding(4.0)
                    .font(.footnote)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .onTapGesture { fileSelected(path, .inNewRow) }
                
                Text("􀏨")
                    .padding(4.0)
                    .font(.callout)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .onTapGesture { fileSelected(path, .inNewPlane) }
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1))
            .onTapGesture { fileSelected(path, .addToRow) }
        case let .directory(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("►")
                
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("􀐙")
                    .font(.callout)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .onTapGesture { genericSelection(
                        .newMultiCommandRecursiveAll(
                            path, .allChildrenInNewPlane
                        )
                    ) }
            }
            .padding(2)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .onTapGesture { fileScopeSelected(scope) }
        case let .expandedDirectory(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("▼")
                
                Text(path.components.last?.rawValue ?? "")
                    .underline()
                    .fontWeight(.heavy)
                
                Spacer()
                
                Text("􀐙")
                    .font(.callout)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .onTapGesture { genericSelection(
                        .newMultiCommandRecursiveAll(
                            path, .allChildrenInNewPlane
                        )
                    ) }
            }
            .padding(2)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.3))
            .onTapGesture { fileScopeSelected(scope) }
        }
    }
    
    // MARK: RectangleDivider
    struct RectangleDivider: View {
        let color: Color = .secondary
        let height: CGFloat = 8.0
        let width: CGFloat = 1.0
        var body: some View {
            Rectangle()
                .fill(color)
                .frame(width: width)
                .edgesIgnoringSafeArea(.horizontal)
        }
    }
    
    @ViewBuilder
    func makeSpacer(_ depth: Int?) -> some View {
        HStack(spacing: 2.0) {
            Spacer()
            RectangleDivider()
        }.frame(
            width: 16.0 * CGFloat(depth ?? 1),
            height: 16.0
        )
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
	func hoverInfo(_ hoveredId: String?) -> some View {
        if let hoveredId = hoveredId {
            List {
                ForEach(sourceInfo.parentList(hoveredId), id: \.self) { semantics in
                    VStack(alignment: .leading) {
                        Text(semantics.syntaxTypeName)
                            .font(.caption)
                            .underline()
                        Text(semantics.referenceName)
                            .font(.caption)
                    }
                    .onTapGesture {
                        selected(id: semantics.syntaxId)
                    }
                }
            }.frame(minHeight: 64)
        } else {
            EmptyView()
        }
	}

    @ViewBuilder
    func infoRows(named: String, from pair: GridAssociationSyntaxToNodeType) -> some View {
        Text(named).underline().padding(.top, 8)
        List {
			ForEach(Array(pair.keys), id:\.self) { (id: SyntaxIdentifier) in
                VStack {
					if let info = sourceInfo.semanticsLookupBySyntaxId[id] {
						Text(info.referenceName)
                            .frame(minWidth: 232, alignment: .leading)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray)
                            )
                            .onTapGesture {
								selected(id: info.syntaxId)
                            }
                    } else {
                        Text("No SemanticInfo")
                    }
                }
            }
        }
        .frame(minWidth: 296.0, maxWidth: 296.0, minHeight: 64)
    }
    
    func fileSelected(_ path: FileKitPath, _ selectType: FileBrowser.Event.SelectType) {
        SceneLibrary.global.codePagesController
            .fileBrowser
            .fileSeletionEvents = .newSingleCommand(path, selectType)
    }
    
    func genericSelection(_ action: FileBrowser.Event) {
        SceneLibrary.global.codePagesController
            .fileBrowser
            .fileSeletionEvents = action
    }
    
    func fileScopeSelected(_ scope: FileBrowser.Scope) {
        SceneLibrary.global.codePagesController.fileBrowser.onScopeSelected(scope)
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
                TestButtons_Debugging()
            }
        }
	}
}

extension SourceInfoGrid {
	private func renderSource() {
		SceneLibrary.global.codePagesController.renderSyntax{ info in
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
            print(error)
            self.error = error as? SceneControllerError
        }
    }
}

#if DEBUG
import SwiftSyntax
struct SourceInfo_Previews: PreviewProvider {
    static var sourceInfo = WrappedBinding<CodeGridSemanticMap>(
        {
            let info = CodeGridSemanticMap()
            return info
        }()
    )
	
	static var hoveredString = WrappedBinding<String>(
		{
			let hovered = ""
			return hovered
		}()
	)

    static var previews: some View {
        SourceInfoGrid(
			sourceInfo: Self.sourceInfo.binding.wrappedValue,
			hoveredToken: Self.hoveredString.binding.wrappedValue
		)
    }
}
#endif
