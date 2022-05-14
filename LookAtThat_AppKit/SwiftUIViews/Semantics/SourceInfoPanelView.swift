//
//  SourceInfoGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import SceneKit
import SwiftUI
import FileKit
import SwiftSyntax
import Combine

struct SourceInfoPanelView: View {
    @StateObject var state: SourceInfoPanelState = SourceInfoPanelState()
    @StateObject var tracingState: SemanticTracingOutState = SemanticTracingOutState()
    
    var sourceInfo: CodeGridSemanticMap { state.sourceInfo }
    var sourceGrid: CodeGrid? { state.sourceGrid }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                if state.show(.directories) {
                    fileBrowserViews()
                }
                
                if state.show(.editor) {
                    #if !TARGETING_SUI
                    CodePagesPopupEditor(
                        state: CodePagesController.shared.editorState
                    )
                    #endif
                }
                
                Spacer()
                
                if state.show(.tracingInfo) {
                    SemanticTracingOutView(state: tracingState)
                }
                
                if state.show(.hoverInfo) {
                    SyntaxHierarchyView()
                }
                
                if state.show(.semanticCategories) {
                    SourceInfoCategoryView()
                        .environmentObject(state)
                }
            }
            FocusSearchInputView()
            if state.show(.tappingControls) {
                FingerTapView()
            }
            windowToggles()
        }
        .frame(alignment: .leading)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
    }
    
    func windowToggles() -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                ForEach(PanelSections.sorted, id: \.self) { section in
                    Toggle(section.rawValue,
                               isOn: state.vendBinding(section)
                    )
                }
            }
        }.padding()
    }
}


// MARK: - File Browser

extension SourceInfoPanelView {
    func fileBrowserViews() -> some View {
        VStack {
            FileBrowserView()
        }
        .border(.black, width: 2.0)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
    }
}

// MARK: - -- Previews --

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
        state.categories.showGlobalMap = true
        return state
    }()
    
    static var semanticTracingOutState: SemanticTracingOutState = {
        let state = SemanticTracingOutState()
//        #if TARGETING_SUI
//        state.allTracedInfo = sourceGrid.codeGridSemanticInfo.allSemanticInfo
//            .filter { !$0.callStackName.isEmpty }
//            .map {
//                TracedInfo.found(out: .init(), trace: (sourceGrid, $0), threadName: "TestThread-X")
//            }
//        #endif
        return state
    }()

    static var previews: some View {
        return Group {
//            SemanticTracingOutView(state: semanticTracingOutState)
//            SourceInfoPanelView(state: sourceState)
            SourceInfoCategoryView()
                .environmentObject(sourceState)
        }.environmentObject(TapObserving.shared)
    }
}
#endif
