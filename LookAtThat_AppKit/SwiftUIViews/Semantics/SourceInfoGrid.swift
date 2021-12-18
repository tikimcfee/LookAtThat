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

struct SourceInfoGrid: View {
    @State var error: SceneControllerError?
    
    @State var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @State var hoveredToken: String?
    @State var searchText: String = ""
    
    var searchBinding: Binding<String> {
        SceneLibrary.global.codePagesController
            .codeGridParser
            .query
            .searchBinding.binding
    }
    
    var body: some View {
        return HStack(alignment: .top) {
            VStack {
                FileBrowserView()
                HStack {
                    TextField(
                        "🔍 Find",
                        text: searchBinding
                    ).frame(width: 256)
                    Text("􀆪")
                        .padding(8.0)
                        .font(.headline)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                        .onTapGesture { newFocusRequested() }
                }
            }
            .border(.black, width: 2.0)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
            
            Spacer()
            
            hoverInfo(hoveredToken)
                .frame(width: 256, height: 256)
            semanticInfo()
        }
        .frame(alignment: .trailing)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
        .onReceive(
            SceneLibrary.global.codePagesController.hoverStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { hoveredToken in
            self.hoveredToken = hoveredToken
        }
        .onReceive(
            SceneLibrary.global.codePagesController.hoverInfoStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { event in
            switch (event) {
            case (.some(let info)):
                self.sourceInfo = info
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    func semanticInfo() -> some View {
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
            }
            .frame(minHeight: 64)
            .padding(4.0)
            .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    func infoRows(named: String, from pair: GridAssociationSyntaxToSyntaxType) -> some View {
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

extension SourceInfoGrid {
    private func renderSource() {
        SceneLibrary.global.codePagesController.renderSyntax{ info in
            sourceInfo = info
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
