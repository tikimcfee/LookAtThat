//
//  SemanticTracingOutView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI

struct SemanticTracingOutView: View {
    @ObservedObject var state: SemanticTracingOutState
    
    var body: some View {
        makeControlsView()
            .padding()
            .frame(width: 640, height: 640)
            .overlay(Rectangle().stroke(Color.gray))
    }
    
    func makeControlsView() -> some View {
        VStack {
            HStack {
                if state.visibleSections.contains(.threadList) {
                    makeLoggedThreadsView()
                }
                Spacer()
                makeButtonsGroup()
            }
            makeFocusedTraceRows()
            makeFileIOControlsView()
        }
        .padding(4)
    }
    
    func makeButtonsGroup() -> some View {
        VStack(alignment: .center) {
            if state.isAutoPlaying {
                HStack {
                    Slider(value: $state.interval, in: state.loopRange, label: {
                        Text(String(format: "%.fms", state.interval))
                    })
                    Button("Stop", action: { state.stopAutoPlay() })
                }
            } else {
                Button("Autoplay", action: { state.startAutoPlay() })
            }
            
            HStack {
                Button("<- Backward", action: { backward() })
                Button("Forward ->", action: { forward() })
            }
        }
    }
    
    @ViewBuilder
    func makeFileIOToggleButton() -> some View {
        if state.tracerState.traceWritesEnabled {
            Button("Stop writing & Save", action: {
                state.tracerState.traceWritesEnabled = false
                TracingRoot.shared.commitMappingState()
            })
        } else {
            Button("Start writing", action: {
                state.tracerState.traceWritesEnabled = true
            })
        }
    }

    func makeFileIOControlsView() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .trailing) {
                makeFileIOToggleButton()
                if state.tracerState.traceWritesEnabled {
                    Button("Reset tracing", action: { state.setupTracing() })
                } else {
                    Button("Start Tracing", action: { state.setupTracing() })
                }
                
                Button("Load logs", action: { reloadsLogs() })
                Button("Delete all logs", action: { removeAllLogs() })
                Button("Reload Wrapper", action: { state.reloadQueryWrapper() })
                Text(state.wrapperInfo)
            }
            .padding(4)
            .overlay(Rectangle().stroke(Color.gray))
            
            List {
                ForEach(state.traceLogFiles, id: \.self) { url in
                    Text("> \(url.lastPathComponent)")
                        .font(Font.system(.body, design: .monospaced))
                        .padding(4.0)
                        .onTapGesture {
                            state.loadTrace(at: url)
                        }
                }.listRowInsets(.none)
            }
        }
        .padding(4)
        .overlay(Rectangle().stroke(Color.gray))
    }
    
    func makeLoggedThreadsView() -> some View {
        VStack {
            Text("Threads (found \(state.loggedThreads.count))")
                .font(Font.system(.body, design: .monospaced))
                .padding(4.0)
            
            HStack(alignment: .top) {
                ForEach(state.threadSlices, id: \.hashValue) { threadSlice in
                    VStack {
                        ForEach(threadSlice, id: \.hash) { thread in
                            Text("[ \(thread.threadName) ]")
                                .font(Font.system(.body, design: .monospaced))
                                .padding(4.0)
                                .background(threadColor(thread))
                                .onTapGesture {
                                    state.setCurrentThread(thread)
                                }
                        }
                    }
                }
            }.overlay(Rectangle().stroke(Color.gray))
        }
    }
    
    @ViewBuilder
    func makeFocusedTraceRows() -> some View {
        VStack {
            if state.visibleSections.contains(.fullTraceList) {
                Button("Hide Trace List (\(state.count) entries)", action: { state.toggleSection(.fullTraceList) })
                ScrollView {
                    LazyVStack {
                        ForEach(state, id: \.id) { match in
                            matchedLineFor(for: match)
                        }
                        .overlay(Rectangle().stroke(Color.gray))
                    }
                }
            } else {
                Button("Show List (\(state.count) entries)", action: { state.toggleSection(.fullTraceList) })
                matchedLineFor(for: state.currentMatch)
            }
        }
    }
    
    @ViewBuilder
    func matchedLineFor(
        for match: MatchedTraceOutput
    ) -> some View {
        switch match {
        case let .indexFault(fault):
            Text("> Index fault! \(fault.position)")
            
        case let .found(found):
            makeTextRow(match, found)
                .onTapGesture {
                    state.zoomTrace(found.trace)
                }
                .background(matchColor(match))
            
        case let .missing(missing):
            makeEmptyRow("""
                    \(missing.out.entryExitName) <?> \(missing.out.callPath)
                    \(missing.threadName)|\(missing.queueName)
                    """)
        }
    }
    
    func matchColor(_ match: MatchedTraceOutput) -> Color {
        state.isCurrent(match)
            ? Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 0.4)
            : Color.clear
    }
    
    func threadColor(_ thread: Thread) -> Color {
        state.isCurrent(thread)
            ? Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0)
            : Color.gray.opacity(0.1)
    }
    
    func logFileColor(_ url: URL) -> Color {
        state.isCurrent(file: url)
            ? Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0)
            : Color.gray.opacity(0.1)
    }
    
    func makeTextRow(
        _ source: MatchedTraceOutput,
        _ found: MatchedTraceOutput.Found
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(found.out.entryExitName) \(found.callPath)")
                    .font(Font.system(.body, design: .monospaced))
                    .lineLimit(1)
                
                if (state.isCurrent(source)) {
                    Text("\(found.trace.info.referenceName)")
                        .font(Font.system(.footnote, design: .monospaced))
                        .lineLimit(1)
                    
                    Text("\(found.trace.grid.fileName.isEmpty ? "No filename" : found.trace.grid.fileName)")
                        .font(Font.system(.footnote, design: .monospaced))
                        .lineLimit(1)
                }
                
                Text("\(found.queueName)")
                    .font(Font.system(.callout, design: .monospaced))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(found.threadName)")
                    .font(Font.system(.callout, design: .monospaced))
            }
        }
        .padding(4)
//        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
    }
    
    @ViewBuilder
    func makeEmptyRow(
        _ text: String
    ) -> some View {
        HStack {
            Text(text)
                .font(Font.system(.caption, design: .monospaced))
            Spacer()
        }
        .padding(4)
//        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
    }
    
    func reloadsLogs() {
        state.reloadTraceFiles()
    }
    
    func removeAllLogs() {
        TracingRoot.shared.removeAllTraces()
    }
    
    func forward() {
        state.increment()
    }
    
    func backward() {
        state.decrement()
    }
}
//#endif

#if DEBUG
import SwiftSyntax

struct SemanticTracing_Previews: PreviewProvider {
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
    
    static var sourceInfo = WrappedBinding<CodeGridSemanticMap>({
        let info = sourceGrid.codeGridSemanticInfo
        return info
    }())
    
    static var randomId: String {
        let characterIndex = sourceString.firstIndex(of: "X") ?? sourceString.startIndex
        let offset = characterIndex.utf16Offset(in: sourceString)
        return sourceGrid.rootNode.nodeId
    }
    
    static var sourceState: SourceInfoPanelState = {
        let state = SourceInfoPanelState()
        state.sourceInfo = Self.sourceInfo.binding.wrappedValue
        state.hoveredToken = Self.randomId
        return state
    }()
    
    static var semanticTracingOutState: SemanticTracingOutState = {
        let state = SemanticTracingOutState()
//        state.setupTracing()
        TracingRoot.shared.capturedLoggingThreads[Thread.current] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        (0...10).forEach { _ in TracingRoot.shared.addRandomEvent() }
#if TARGETING_SUI
        SemanticTracingOutState.randomTestData = sourceGrid.codeGridSemanticInfo.allSemanticInfo
            .filter { !$0.callStackName.isEmpty }
            .map {
                Bool.random()
                ? .found(MatchedTraceOutput.Found(
                    out: TraceLine.random,
                    trace: (sourceGrid, $0)
                ))
                : .missing(MatchedTraceOutput.Missing(
                    out: TraceLine.random
                ))
            }
#endif
        state.reloadQueryWrapper()
        state.setCurrentThread(Thread.current)
        return state
    }()
    
    static var previews: some View {
        return Group {
            SemanticTracingOutView(state: semanticTracingOutState)
        }
    }
}
#endif
