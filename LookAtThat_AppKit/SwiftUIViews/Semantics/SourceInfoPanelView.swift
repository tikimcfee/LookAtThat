//
//  SourceInfoGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SceneKit
import SwiftUI
import FileKit
import SwiftSyntax
import Combine

class SourceInfoPanelState: ObservableObject {
    @Published var error: SceneControllerError?
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var hoveredToken: String = ""
    @Published var searchText: String = ""
    
    private var bag = Set<AnyCancellable>()
    
    var searchBinding: Binding<String> {
        SceneLibrary.global.codePagesController
            .codeGridParser
            .query
            .searchBinding.binding
    }
    
    init() {
        #if !TARGETING_SUI
        setupBindings()
        #endif
    }
    
    func setupBindings() {
        SceneLibrary.global.codePagesController.hoverStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink {
                self.hoveredToken = $0
            }
            .store(in: &bag)
        
        SceneLibrary.global.codePagesController.hoverInfoStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch (event) {
                case (.some(let info)):
                    self.sourceInfo = info
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}

struct SourceInfoPanelView: View {
    @StateObject var state: SourceInfoPanelState = SourceInfoPanelState()
    
    var sourceInfo: CodeGridSemanticMap { state.sourceInfo }
    
    var body: some View {
        return HStack(alignment: .top) {
            VStack {
                FileBrowserView()
                searchControlView()
            }
            .border(.black, width: 2.0)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
            
            Spacer()
            
            hoveredNodeInfoView(state.hoveredToken)
            semanticCategoryViews()
        }
        .frame(alignment: .trailing)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
    }
    
    @ViewBuilder
    func searchControlView() -> some View {
        HStack {
            TextField(
                "🔍 Find",
                text: state.searchBinding
            ).frame(width: 256)
            Text("New Focus")
                .padding(8.0)
                .font(.headline)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                .onTapGesture { newFocusRequested() }
        }
    }
    
    @ViewBuilder
    func semanticCategoryViews() -> some View {
        VStack(spacing: 0) {
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
        }
    }
    
    @ViewBuilder
    func hoveredNodeInfoView(_ hoveredId: String) -> some View {
        VStack {
            Text("Target: \(hoveredId)")
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(sourceInfo.parentList(hoveredId), id: \.self) { semantics in
                        semanticRow(semantics: semantics)
                    }
                }
                .padding(4.0)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
            }
        }
        .frame(
            minWidth: 256.0, maxWidth: 296.0,
            minHeight: 128.0
        )
        .padding(4.0)
    }
    
    @ViewBuilder
    func semanticRow(semantics: SemanticInfo) -> some View {
        VStack(alignment: .leading) {
            Text(semantics.syntaxTypeName)
                .font(.caption)
                .underline()
            Text(semantics.referenceName)
                .font(.caption)
        }
        .padding([.horizontal], 8.0)
        .padding([.vertical], 4.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .border(Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0), width: 1.0)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
        .onTapGesture {
            selected(id: semantics.syntaxId)
        }
    }
    
    @ViewBuilder
    func infoRows(named: String, from pair: AssociatedSyntaxMap) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(named).underline().padding(.top, 8)
            List {
                ForEach(Array(pair.keys), id:\.self) { (id: SyntaxIdentifier) in
                    if let info = sourceInfo.semanticsLookupBySyntaxId[id] {
                        Text(info.referenceName)
                            .font(Font.system(.caption, design: .monospaced))
                            .padding(4)
                            .overlay(
                                Rectangle().stroke(Color.gray)
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
        .frame(minWidth: 296.0, maxWidth: 296.0, minHeight: 64.0)
        .padding(4.0)
        .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
    }
    
    func newFocusRequested() {
        SceneLibrary.global.codePagesController.compat
            .inputCompat.focus.setNewFocus()
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

extension SourceInfoPanelView {
    private func renderSource() {
        SceneLibrary.global.codePagesController.renderSyntax{ info in
            state.sourceInfo = info
        }
    }
}


#if DEBUG
import SwiftSyntax
struct SourceInfo_Previews: PreviewProvider {
    static let sourceString = """
func helloWorld() {
  let test = ""
  let another = "X"
  let somethingCrazy: () -> Void = { [weak self] in
     print("Hello, world!")
  }
  somethingCrazy()
}
"""
    
    static var sourceGrid: CodeGrid = {
        let parser = CodeGridParser()
        let grid = parser.renderGrid(sourceString)!
        return grid
    }()
    
    static var sourceInfo = WrappedBinding<CodeGridSemanticMap>({
        let info = sourceGrid.codeGridSemanticInfo
        return info
    }())
    
    static var randomId: String {
        let characterIndex = sourceString.firstIndex(of: "X") ?? sourceString.startIndex
        let offset = characterIndex.utf16Offset(in: sourceString)
        return sourceGrid.rawGlyphsNode.childNodes[offset].name ?? "no-id"
    }
    
    static var sourceState: SourceInfoPanelState = {
        let state = SourceInfoPanelState()
        state.sourceInfo = Self.sourceInfo.binding.wrappedValue
        state.hoveredToken = Self.randomId
        return state
    }()

    static var previews: some View {
        return SourceInfoPanelView(state: sourceState)
    }
}
#endif
