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
    @StateObject var tracingState: SemanticTracingOutState = SemanticTracingOutState()
    
    var body: some View {
        VStack {
            allPanelsGroup
        }
        .frame(alignment: .leading)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
        .padding(8)
    }
}

extension SourceInfoPanelView {
    
    var allPanelsGroup: some View {
        ForEach(state.visiblePanelSlices, id: \.self) { panelSlice in
            ForEach(panelSlice, id: \.self) { panel in
                floatingView(for: panel)
                if (panelSlice.last != panel) {
                    Spacer()
                }
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
    
    struct WordInputView: View {
        
        @State var textInput: String = ""
        @State var toggledRows: Set<String> = []
        
        @State var playingList: Bool = false
//        {
//            didSet {
//                if !playingList {
//                    autoscrollWord = nil
//                }
//            }
//        }
        
        @State var goSlow: Bool = true
//        @State var autoscrollWord: String?
        
        @StateObject var controller = DictionaryController()
        
        var body: some View {
            VStack(alignment: .leading) {
                dictionaryView
                TextField("Word goes here", text: $textInput)
                
                HStack {
                    Button("Load Dictionary") {
                        controller.start()
                    }
                    
                    Button("Refresh Wall") {
                        GlobalInstances
                            ._2ETRoot
                            .setupDictionaryTest(controller)
                    }
                    
                    Button(
                        action: { toggleListPlay() },
                        label: {
                            if playingList {
                                HStack {
                                    Text("Stop List Play")
                                    ProgressView()
                                }
                            } else {
                                Text("Play List")
                            }
                        }
                    )
                    
                    Button("Play sentence") {
                        playInputAsSentence(textInput)
                    }
                    
                    Toggle("Go Slow", isOn: $goSlow)
                }
            }
            .padding()
            .onChange(of: textInput) { newValue in
                updateFocusOnTextChange(newValue)
            }
        }
        
        func toggleListPlay() {
            guard !playingList else {
                playingList = false
                return
            }
            
            playingList = true
            
            WorkerPool.shared.nextConcurrentWorker().async {
                startPlay()
            }
            
            func startPlay() {
                var iterator = controller.sortedDictionary.sorted.makeIterator()
                func nextWord() -> String? { iterator.next()?.0 }
                while let word = nextWord(), playingList {
//                    autoscrollWord = word
                    updateFocusOnTextChange(word)
                    
                    if goSlow {
                        Thread.sleep(forTimeInterval: 0.033)
                    }
                }
                Task { @MainActor in playingList = false }
            }
        }
        
        func playInputAsSentence(_ dirtySentence: String) {
            let cleanedSentence = dirtySentence.lowercased().splitToWords.map {
                $0.trimmingCharacters(in: .alphanumerics.inverted).lowercased()
            }
            
            WorkerPool.shared.nextWorker().async {
                for word in cleanedSentence {
                    updateFocusOnTextChange(word)
                    
                    if goSlow {
                        Thread.sleep(forTimeInterval: 0.033)
                    }
                }
            }
        }
        
        func updateFocusOnTextChange(_ dirtyInput: String) {
            let cleanInput = dirtyInput.lowercased()
            
            guard let node = controller.nodeMap[cleanInput] else {
                print("No word found for: \(cleanInput)")
                controller.focusedWordNode = nil
                return
            }
            
            controller.focusedWordNode = node
//            GlobalInstances.debugCamera.interceptor.resetPositions()
//            GlobalInstances.debugCamera.position = node.position.translated(dZ: -10)
//            GlobalInstances.debugCamera.rotation = .zero
        }
        
        @ViewBuilder
        var dictionaryView: some View {
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(controller.sortedDictionary.sorted, id: \.0) { entry in
                            dictionaryViewCell(for: entry)
                                .padding(.bottom, 8)
                                .tag(entry.0)
                        }
                    }
                    .id(UUID()) // Use .id() to force rebuilding without diff computation
                }
//                .onChange(of: autoscrollWord) { word in
//                    guard goSlow, let word else { return }
////                    reader.scrollTo(word)
//                }
            }
            .frame(maxHeight: 380.0)
        }
        
        @ViewBuilder
        func dictionaryViewCell(for entry: (String, [String])) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.0)
                if toggledRows.contains(entry.0) {
                    Text(entry.1.joined(separator: ", "))
                }
            }
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 4, trailing: 6))
            .background(cellBackground(for: entry))
            .onTapGesture {
                toggledRows.removeAll()
                toggledRows.insert(entry.0)
                
//                let toggled = toggledRows.toggle(entry.0)
//                print("'\(entry.0)' toggled: \(toggled)")
                
                if let node = controller.nodeMap[entry.0] {
                    controller.focusedWordNode = node
                } else {
                    controller.focusedWordNode = nil
                }
            }
        }
        
        func cellBackground(for entry: (String, [String])) -> some View {
            ZStack {
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
//                    .fill(
//                        autoscrollWord == entry.0
//                            ? .gray.opacity(0.6)
//                            : .gray.opacity(0.2)
//                    )
                    .fill(.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                    .stroke(.gray)
            }.drawingGroup(opaque: true)
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
            .environmentObject(state)
    }
    
    @ViewBuilder
    var hoverInfoView: some View {
        SyntaxHierarchyView()
    }

    @ViewBuilder
    var traceInfoView: some View {
        SemanticTracingOutView(state: tracingState)
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
        FileBrowserView()
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
