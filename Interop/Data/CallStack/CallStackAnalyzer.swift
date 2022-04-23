import Foundation
import SwiftTrace

class RuntimeTracer {
    var logOutput = [String]()
    
    init() {
        setupTracing()
    }
    
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        
        let types = [
            CodeGrid.self,
            CodeGridParser.self,
            CodeGrid.Measures.self,
            CodeGrid.Renderer.self,
            CodeGrid.AttributedGlyphs.self,
            SemanticInfoBuilder.self,
            GridCache.self,
            GlyphLayerCache.self
        ] as [AnyClass]
        
        types.forEach {
            SwiftTrace.trace(aClass: $0)
            let parser = SwiftTrace.interpose(aType: $0)
            print("interposed '\($0)': \(parser)")
        }
    }
    
    func onLog(_ out: TraceOutput) {
        if let components = out.callComponents {
            logOutput.append("\(out.name) \(components.function)")
        }
    }
}

extension TraceOutput {
    private static let Module = "LookAtThat_AppKit."
    private static let CallSeparator = " -> "
    
    var name: String {
        switch self {
        case .entry: return "(Enter)"
        case .exit: return "(Exit)"
        }
    }
    
    var callComponents: (function: String, returnType: String)? {
        let split = decorated.components(separatedBy: Self.CallSeparator)
        guard split.count == 2 else { return nil }
        let rawFunction = split[0]
        let argIndex = rawFunction.firstIndex(of: "(") ?? rawFunction.endIndex
        let strippedArgs = rawFunction.prefix(upTo: argIndex)
            .replacingOccurrences(of: Self.Module, with: "")
        return (String(strippedArgs), split[1])
    }
}

