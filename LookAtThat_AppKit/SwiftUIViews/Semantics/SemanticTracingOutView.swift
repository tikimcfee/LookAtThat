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
        makeButtonsGroup()
        makeAllRows()
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
    func makeAllRows() -> some View {
        VStack(alignment: .leading) {
            ForEach(state.focusContext, id: \.self) { info in
                switch info {
                case let .found(output, matchedTrace, thread, _) where state.isCurrent(info):
                    makeTextRow(matchedTrace, output, thread, true)
                        .background(Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0))
                        .onTapGesture { state.toggleTrace(matchedTrace) }
                    
                case let .found(output, matchedTrace, thread, _):
                    makeTextRow(matchedTrace, output, thread, false)
                        .onTapGesture { state.toggleTrace(matchedTrace) }
                    
                case let .missing(out, thread, _):
                    makeEmptyRow("\(out.name) \(out.callComponents.callPath) \(thread)")
                    
                case .none:
                    makeEmptyRow("...")
                }
            }
        }
    }
    
    @ViewBuilder
    func makeTextRow(
        _ traceValue: TraceValue,
        _ output: TraceOutput,
        _ thread: String,
        _ isCurrent: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8.0) {
                Text("\(output.name) \(output.callComponents.callPath)")
                    .font(Font.system(.body, design: .monospaced))
                if (isCurrent) {
//                    Text("\(traceValue.info.referenceName)")
//                        .font(Font.system(.footnote, design: .monospaced))
                    Text("\(traceValue.grid.fileName.isEmpty ? "..." : traceValue.grid.fileName)")
                        .font(Font.system(.footnote, design: .monospaced))
                }
            }
            Spacer()
            Text("\(thread)")
                .font(Font.system(.callout, design: .monospaced))
        }
        .frame(width: 480, alignment: .leading)
        .padding(4)
        .overlay(Rectangle().stroke(Color.gray))
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
    }
    
    @ViewBuilder
    func makeEmptyRow(
        _ text: String
    ) -> some View {
        HStack {
            Text(text).font(Font.system(.caption, design: .monospaced))
        }
        .frame(width: 480, alignment: .leading)
        .padding(4)
        .overlay(Rectangle().stroke(Color.gray))
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
        
        
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
        state.isSetup = true
        (0...10).forEach { _ in
            TracingRoot.shared.logOutput.append(
                (TraceOutput.random, Thread.current)
            )
        }
        state.prepareQueryWrapper()
        
#if TARGETING_SUI
        SemanticTracingOutState.randomTestData = sourceGrid.codeGridSemanticInfo.allSemanticInfo
            .filter { !$0.callStackName.isEmpty }
            .map {
                MatchedTraceOutput.found(
                    out: TraceOutput.random,
                    trace: (sourceGrid, $0),
                    threadName: "TestThread"
                )
            }
#endif
        return state
    }()
    
    static var previews: some View {
        return Group {
            SemanticTracingOutView(state: semanticTracingOutState)
        }
    }
}
#endif
