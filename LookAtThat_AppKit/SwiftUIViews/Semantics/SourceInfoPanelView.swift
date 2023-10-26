//
//  SourceInfoGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import SwiftUI
import Combine

struct SourceInfoPanelView: View {
    @StateObject var state: SourceInfoPanelState = SourceInfoPanelState()
    
    #if !os(iOS)
    @StateObject var tracingState: SemanticTracingOutState = SemanticTracingOutState()
    #endif
    
    var body: some View {
//        VStack(alignment: .leading) {
            allPanelsGroup
//        }
    }
}

extension SourceInfoPanelView {
    
    var allPanelsGroup: some View {
        ForEach(state.visiblePanelSlices, id: \.self) { panelSlice in
            ForEach(panelSlice, id: \.self) { panel in
                floatingView(for: panel)
            }
        }
    }
    
    @ViewBuilder
    func floatingView(for panel: PanelSections) -> some View {
        FloatableView(
            displayMode: state.vendPanelBinding(panel),
            windowKey: panel,
            resizableAsSibling: true,
            innerViewBuilder: {
                panelView(for: panel)
                    .border(.black, width: 2.0)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
            }
        )
    }
    
    @ViewBuilder
    func panelView(for panel: PanelSections) -> some View {
        switch panel {
        case .appStatusInfo:
            appStatusView
        case .gridStateInfo:
            gridStateView
        case .globalSearch:
            globalSearchView
        case .editor:
            editorView
        case .directories:
            fileBrowserView
        case .semanticCategories:
            semanticCategoriesView
        case .hoverInfo:
            hoverInfoView
        case .tracingInfo:
            traceInfoView
        case .windowControls:
            windowControlsView
        case .githubTools:
            gitHubTools
        case .focusState:
            focusState
        case .wordInput:
            wordInputView
        }
    }
    
    @ViewBuilder
    var wordInputView: some View {
        WordInputView()
    }
    
    @ViewBuilder
    var focusState: some View {
        WorldFocusView(
            focus: GlobalInstances.gridStore.worldFocusController
        )
    }
    
    @ViewBuilder
    var appStatusView: some View {
        AppStatusView(
            status: GlobalInstances.appStatus
        )
    }
    
    @ViewBuilder
    var gitHubTools: some View {
        GitHubClientView()
    }
    
    @ViewBuilder
    var gridStateView: some View {
        // TODO: This isn't global yet, but it can / should / will be
        Text("Grid state view not yet reimplemented")
            .padding(32)

    }
    
    var globalSearchView: some View {
        GlobalSearchView()
    }
    
    @ViewBuilder
    var semanticCategoriesView: some View {
        SourceInfoCategoryView()
            .frame(width: 780, height: 640)
            .environmentObject(state)
    }
    
    @ViewBuilder
    var hoverInfoView: some View {
        SyntaxHierarchyView()
    }

    @ViewBuilder
    var traceInfoView: some View {
        #if !os(iOS)
        SemanticTracingOutView(state: tracingState)
        #else
        Text("No tracin' on mobile because abstractions.")
        #endif
    }
    
    @ViewBuilder
    var editorView: some View {
#if !TARGETING_SUI
        CodePagesPopupEditor(
            state: GlobalInstances.editorState
        )
#endif
    }
    
    @ViewBuilder
    var fileBrowserView: some View {
        FileBrowserView(
            browserState: state.fileBrowserState
        )
    }
    
    var windowControlsView: some View {
        SourceInfoPanelToggles(state: state)
    }
}

// MARK: - -- Previews --

#if DEBUG
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
        let cache = GridCache()
        let grid = cache.renderGrid(sourceString)!
        return grid
    }()
    
    static var sourceInfo = WrappedBinding<SemanticInfoMap>({
        let info = sourceGrid.semanticInfoMap
        return info
    }())
    
    static var randomId: String {
//        let characterIndex = sourceString.firstIndex(of: "X") ?? sourceString.startIndex
//        let offset = characterIndex.utf16Offset(in: sourceString)
        return "no-id" // TODO: Expose node ids somehow
    }
    
    static var sourceState: SourceInfoPanelState = {
        let state = SourceInfoPanelState()
        return state
    }()
    
    #if !os(iOS)
    static var semanticTracingOutState: SemanticTracingOutState = {
        let state = SemanticTracingOutState()
//        #if TARGETING_SUI
//        state.allTracedInfo = sourceGrid.semanticInfoMap.allSemanticInfo
//            .filter { !$0.callStackName.isEmpty }
//            .map {
//                TracedInfo.found(out: .init(), trace: (sourceGrid, $0), threadName: "TestThread-X")
//            }
//        #endif
        return state
    }()
    #endif

    static var previews: some View {
        return Group {
//            SemanticTracingOutView(state: semanticTracingOutState)
//            SourceInfoPanelView(state: sourceState)
            SourceInfoCategoryView()
                .environmentObject(sourceState)
        }
    }
}
#endif
