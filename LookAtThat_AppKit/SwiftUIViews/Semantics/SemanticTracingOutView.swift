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
        VStack(alignment: .center, spacing: 16.0) {
            if !state.isSetup {
                makeSetupView()
            } else if state.allTracedInfo.isEmpty {
                makeEmtyView()
            } else {
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
    func makeEmtyView() -> some View {
        Button("Load from trace", action: { state.computeTraceInfo() })
    }
    
    @ViewBuilder
    func makeControlsView() -> some View {
        VStack(alignment: .leading) {
            ForEach(state.focusContext, id: \.self) { info in
                switch info {
                case let .found(_, trace, _, _) where state.isCurrent(info):
                    makeTextRow(trace.info.referenceName)
                        .background(Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0))
                        .onTapGesture { state.toggleTrace(trace) }
                case let .found(_, trace, _, _):
                    makeTextRow(trace.info.referenceName)
                        .onTapGesture { state.toggleTrace(trace) }
                default:
                    makeTextRow("...")
                }
            }
        }
        VStack(alignment: .center) {
            HStack {
                Button("<- Backward", action: { backward() })
                Button("Forward ->", action: { forward() })
            }
            Spacer().frame(height: 16.0)
            if state.isAutoPlaying {
                Button("Stop", action: { state.stopAutoPlay() })
            } else {
                Button("Autoplay", action: { state.startAutoPlay() })
            }
        }
        .frame(width: 256.0)
    }
    
    @ViewBuilder
    func makeTextRow(_ text: String) -> some View {
        Text(text)
            .font(Font.system(.caption, design: .monospaced))
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
#if TARGETING_SUI
//        state.setupTracing()
        state.isSetup = true
        state.allTracedInfo = sourceGrid.codeGridSemanticInfo.allSemanticInfo
            .filter { !$0.callStackName.isEmpty }
            .map {
                TracedInfo.found(out: .init(), trace: (sourceGrid, $0), threadName: "TestThread")
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
