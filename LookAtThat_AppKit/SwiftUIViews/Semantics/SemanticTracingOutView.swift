//
//  SemanticTracingOutView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI

//#if !TARGETING_SUI
class SemanticTracingOutState: ObservableObject {
    
    @Published var currentIndex = 0
    @Published var allTracedInfo =  [TracedInfo]()
    
    @Published var isSetup = false
    @Published var isAutoPlaying = false
    
    private var lastIndex: Int { currentIndex - 1 }
    private var nextIndex: Int { currentIndex + 1 }
    
    var lastInfo: TracedInfo? {
        return allTracedInfo.indices.contains(lastIndex)
        ? allTracedInfo[lastIndex] : nil
    }
    
    var thisInfo: TracedInfo? {
        return allTracedInfo.indices.contains(currentIndex)
        ? allTracedInfo[currentIndex] : nil
    }
    
    var nextInfo: TracedInfo? {
        return allTracedInfo.indices.contains(nextIndex)
        ? allTracedInfo[nextIndex] : nil
    }
    
    func startAutoPlay() {
        guard !isAutoPlaying else { return }
        isAutoPlaying = true
        QuickLooper(
            interval: .seconds(1),
            loop: { self.increment() }
        ).runUntil { !self.isAutoPlaying }
    }
    
    func stopAutoPlay() {
        isAutoPlaying = false
    }
    
    func increment() {
        toggleTrace(thisInfo?.maybeTrace)
        currentIndex += 1
        toggleTrace(thisInfo?.maybeTrace)
    }
    
    func decrement() {
        toggleTrace(thisInfo?.maybeTrace)
        currentIndex -= 1
        toggleTrace(thisInfo?.maybeTrace)
    }
    
    func toggleTrace(_ trace: TraceValue?) {
        guard let trace = trace else {
            return
        }
        trace.grid.toggleGlyphs()
        SceneLibrary.global.codePagesController.selected(
            id: trace.info.syntaxId,
            in: trace.grid.codeGridSemanticInfo
        )
    }
    
    #if !TARGETING_SUI
    func setupTracing() {
        TracingRoot.shared.setupTracing()
        self.isSetup = true
    }
    
    func computeTraceInfo() {
        let cache = SceneLibrary.global.codePagesController.codeGridParser.gridCache
        let allGrid = cache.cachedGrids.values.map { $0.source }
        self.allTracedInfo = SemanticMapTracer.start(
            sourceGrids: allGrid,
            sourceTracer: TracingRoot.shared
        )
    }
    #else
    func computeTraceInfo() {
        print("\n\n\t\tTRACING DISABLED!\n\n")
    }
    
    func setupTracing() {
        print("\n\n\t\tTRACING DISABLED!\n\n")
    }
    #endif
}

struct SemanticTracingOutView: View {
    @ObservedObject var state: SemanticTracingOutState
    
    var body: some View {
        HStack(alignment: .center) {
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
            if let last = state.lastInfo?.maybeTrace {
                makeInfoView(last)
            } else {
                Text("...")
            }
            
            if let current = state.thisInfo?.maybeTrace {
                makeInfoView(current)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0))
            } else {
                Text("<No current>")
            }
            
            if let next = state.nextInfo?.maybeTrace {
                makeInfoView(next)
            } else {
                Text("...")
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
    }
    
    @ViewBuilder
    func makeInfoView(_ trace: TraceValue) -> some View {
        Text(trace.info.referenceName)
            .font(Font.system(.caption, design: .monospaced))
            .frame(minWidth: 256.0, alignment: .leading)
            .padding(4)
            .overlay(Rectangle().stroke(Color.gray))
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)) // needed to fill tap space on macOS
            .onTapGesture { state.toggleTrace(trace) }
    }
    
    func forward() {
        state.increment()
    }
    
    func backward() {
        state.decrement()
    }
}
//#endif
