//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

import Combine
import BitHandling

extension TracingRoot {
    class State: ObservableObject {
        @Published var traceWritesEnabled = false
        @Published var didEnableTracing = false
        private var bag = Set<AnyCancellable>()
        
        init() {
            $traceWritesEnabled.dropFirst().sink {
                PersistentThreadTracer.SHOULD_WRITE = $0
            }.store(in: &bag)
        }
    }
}

class TracingRoot {
    static var shared = TracingRoot()
    
    lazy var capturedLoggingThreads = ConcurrentDictionary<Thread, Int>()
    lazy var capturedLoggingQueues = ConcurrentDictionary<String, Int>()
    let tracingConsumer = TracingRootConsumer()
    let state = State()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        capturedLoggingThreads[Thread.current] = 1
        capturedLoggingQueues[currentQueueName()] = 1
        tracingConsumer.storeTraceLog(out)
    }
    
    func getCurrentQueueTraceLogs() -> PersistentThreadTracer? {
        tracingConsumer.getTraceLogs()
    }
    
    func loadTrace(from file: URL) throws -> PersistentThreadTracer {
        try tracingConsumer.threadTracer(from: file)
    }
    
    func addRandomEvent() {
        tracingConsumer.addRandomEvent()
    }
    
    func commitMappingState() {
        tracingConsumer.commitGroupTracerState()
    }
    
    func removeAllTraces() {
        tracingConsumer.removeAllLogTraces()
    }
    
    func removeMapping() {
        tracingConsumer.removeMapping()
    }
}

#if !TARGETING_SUI && !StripSwiftTrace
import SwiftTrace
extension TracingRoot {
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        
        for tracingClass in FullTracingClassList {
            SwiftTrace.trace(aClass: tracingClass)
            let result = SwiftTrace.interpose(aType: tracingClass)
            print("Tracing Interposed '\(tracingClass)':, symbols: \(result)")
        }
    }
    
    func stopTracingAll() {
        SwiftTrace.revertInterposes()
        SwiftTrace.removeAllTraces()
    }
}
#else
extension TracingRoot {
    func setupTracing() {
        print("\n\n\t\t Tracing not compiled in!")
    }
    
    func stopTracingAll() {
        print("\n\n\t\t Tracing not compiled in!")
    }
}
#endif

// TODO: Careful with recursive locks on main in the tracing route.
// AppendingStore has this problem, most tracing classes as well.
fileprivate let FullTracingClassList: [AnyClass] = [
    
]
