//
//  SemanticTracingOutView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI

#if !TARGETING_SUI
import SwiftTrace
#endif

struct SemanticTracingOutView: View {
    @ObservedObject var state: SemanticTracingOutState
    
    var body: some View {
        VStack(alignment: .center, spacing: 16.0) {
            if !state.isSetup {
                makeSetupView()
            }
            else if !state.isWrapperLoaded {
                makeRequestLoadView()
            }
            else {
                makeControlsView()
            }
        }
        .padding()
        .frame(maxWidth: 640, maxHeight: 540)
        .overlay(Rectangle().stroke(Color.gray))
    }
    
    @ViewBuilder
    func makeSetupView() -> some View {
        Button("Setup Tracing", action: { state.setupTracing() })
    }
    
    @ViewBuilder
    func makeRequestLoadView() -> some View {
        Button("Load from trace", action: { state.prepareQueryWrapper() })
    }
    
    @ViewBuilder
    func makeControlsView() -> some View {
        VStack {
            makeButtonsGroup()
            makeFocusedTraceRows()
            makeLoggedThreadsView()
        }
    }
    
    @ViewBuilder
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
                                    state.focusedThread = thread
                                }
                        }.listRowInsets(.none)
                    }
                }
            }.overlay(Rectangle().stroke(Color.gray))
        }
    }
    
    @ViewBuilder
    func makeFocusedTraceRows() -> some View {
        List {
            ForEach(state.focusContext, id: \.id) { match in
                switch match {
                case let .found(found):
                    makeTextRow(match, found)
                        .onTapGesture { state.toggleTrace(found.trace) }
                        .listRowInsets(.none)
                        .listRowBackground(matchColor(match))
                    
                case let .missing(missing):
                    makeEmptyRow("""
                    \(missing.out.name) <?> \(missing.out.callComponents.callPath)
                    \(missing.threadName)|\(missing.queueName)
                    """)
                    .listRowInsets(.none)
                }
            }
            .overlay(Rectangle().stroke(Color.gray))
        }.listStyle(.plain)
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
    
    @ViewBuilder
    func makeTextRow(
        _ source: MatchedTraceOutput,
        _ found: MatchedTraceOutput.Found
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(found.out.name) \(found.out.callComponents.callPath)")
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
    
    static var semanticTracingOutState: SemanticTracingOutState = {
        let state = SemanticTracingOutState()
//        state.setupTracing()
        TracingRoot.shared.capturedLoggingThreads[Thread.current] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        TracingRoot.shared.capturedLoggingThreads[Thread()] = 1
        state.isSetup = true
        (0...10).forEach { _ in
            Thread.storeTraceLog(TraceOutput.random)
        }
#if TARGETING_SUI
        SemanticTracingOutState.randomTestData = sourceGrid.codeGridSemanticInfo.allSemanticInfo
            .filter { !$0.callStackName.isEmpty }
            .map {
                Bool.random()
                ? .found(MatchedTraceOutput.Found(
                    out: TraceOutput.random,
                    trace: (sourceGrid, $0),
                    threadName: Thread.current.threadName,
                    queueName: "MainThread"
                ))
                : .missing(MatchedTraceOutput.Missing(
                    out: TraceOutput.random,
                    threadName: "Thread.current.threadName",
                    queueName: "NoQueueTestz"
                ))
            }
#endif
        state.prepareQueryWrapper()
        state.focusedThread = Thread.current
        return state
    }()
    
    static var previews: some View {
        return Group {
            SemanticTracingOutView(state: semanticTracingOutState)
        }
    }
}
#endif
