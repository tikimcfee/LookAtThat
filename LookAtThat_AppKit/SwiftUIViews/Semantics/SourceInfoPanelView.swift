//
//  SourceInfoGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import SwiftUI
import Combine
import MetalLink
import SwiftGlyphs

struct SourceInfoPanelView: View {
    @StateObject var state: SourceInfoPanelState = SourceInfoPanelState()
    
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
        }
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
        GridWutView()
    }
    
    struct GridWutView: View {
        // TODO: Split all this mess up. Getting crazier by the day.
        @State private var currentHoveredGrid: GridPickingState.Event?
        @State private var cameraPosition: LFloat3?
        
        var body: some View {
            VStack {
                if let state = currentHoveredGrid?.latestState {
                    Text(state.targetGrid.fileName)
                    Text(state.targetGrid.dumpstats)
                }
            }
            .frame(minWidth: 420, minHeight: 420)
            .onReceive(
                GlobalInstances.gridStore
                    .nodeHoverController
                    .sharedGridEvent
                    .subscribe(on: RunLoop.main)
                    .receive(on: RunLoop.main),
                perform: { hoveredGrid in
                    self.currentHoveredGrid = hoveredGrid
                }
            )
        }
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
        Text("No tracin' on desktop because we movin' on.")
        #else
        Text("No tracin' on mobile because abstractions.")
        #endif
    }
    
    @ViewBuilder
    var editorView: some View {
#if !TARGETING_SUI
        Text("Editor not implemented. Again.")
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

    static var previews: some View {
        return Group {
            SourceInfoCategoryView()
                .environmentObject(sourceState)
        }
    }
}
#endif
