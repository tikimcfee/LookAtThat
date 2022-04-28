//
//  TracedInfoBridging.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
#else
enum TraceOutput {
    case entry(invocation: String, method: Method?, decorated: String, subLog: Bool)
    case exit (invocation: String, method: Method?, decorated: String, subLog: Bool)
    public var decorated: String {
        switch self {
        case .entry(_, _, let decorated, _): return decorated
        case .exit(_, _, let decorated, _): return decorated
        }
    }
}
#endif

typealias TraceValue = (grid: CodeGrid, info: SemanticInfo)

enum MatchedTraceOutput {
    case missing(Missing)
    case found(Found)
    
    struct Missing {
        let out: TraceOutput
        let threadName: String
        let queueName: String
        let stamp: String = UUID().uuidString
    }
    
    struct Found {
        let out: TraceOutput
        let trace: TraceValue
        let threadName: String
        let queueName: String
        let stamp: String = UUID().uuidString
    }
}

extension MatchedTraceOutput: Identifiable, Hashable {
    static func == (lhs: MatchedTraceOutput, rhs: MatchedTraceOutput) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String { stamp }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension MatchedTraceOutput {
    var out: TraceOutput {
        switch self {
        case let .missing(missing): return missing.out
        case let .found(found): return found.out
        }
    }
    
    var stamp: Self.ID {
        switch self {
        case let .missing(missing): return missing.stamp
        case let .found(found): return found.stamp
        }
    }
    
    var thread: String {
        switch self {
        case let .missing(missing): return missing.threadName
        case let .found(found): return found.threadName
        }
    }
    
    var queue: String {
        switch self {
        case let .missing(missing): return missing.queueName
        case let .found(found): return found.queueName
        }
    }
    
    var maybeTrace: TraceValue? {
        switch self {
        case let .found(found): return found.trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case let .found(found): return found.trace.info
        default: return nil
        }
    }
}

// MARK: - Signature cleaning

extension TraceOutput {
    private static let Module = "LookAtThat_AppKit"
    private static let StopCharacters = CharacterSet(charactersIn: "():")
    
    static func cleanComponent(_ component: String) -> (String, foundStop: Bool) {
        var foundStop = false
        let prefixed = component.prefix(while: { character in
            foundStop = !character.unicodeScalars.allSatisfy { !StopCharacters.contains($0) }
            return !foundStop
        })
        let trimmed = String(prefixed).trimmingCharacters(in: CharacterSet.whitespaces)
        return (trimmed, foundStop)
    }
    
    var callComponents: (callPath: String, allComponents: [String]) {
        var shouldContinue = true
        var allComponents = [String]()
        let simplifiedStack = signature
            .components(separatedBy: ".")
            .reduce(into: "") { currentPath, component in
                guard shouldContinue, component != Self.Module else { return }
                let (cleanedComponent, foundStop) = Self.cleanComponent(component)
                
                shouldContinue = !foundStop
                allComponents.append(cleanedComponent)
                if currentPath.isEmpty {
                    currentPath.append(cleanedComponent)
                } else {
                    currentPath.append(".\(cleanedComponent)")
                }
            }
        return (simplifiedStack, allComponents)
    }
}

extension TraceOutput {
    var name: String {
        switch self {
        case .entry: return "-> "
        case .exit:  return "<- "
        }
    }
    
    var isEntry: Bool {
        switch self {
        case .entry: return true
        case .exit:  return false
        }
    }
    
    var isExit: Bool {
        switch self {
        case .entry: return false
        case .exit:  return true
        }
    }
    
    #if TARGETING_SUI
    static var randomInvoke: String { "" }
    var signature: String { decorated }
    #else
    static var randomInvoke: SwiftTrace.Swizzle.Invocation { .current }
    var signature: String {
        switch self {
        case .entry(let invocation, _, _, _):
            return invocation.swizzle.signature
        case .exit(let invocation, _, _, _):
            return invocation.swizzle.signature
        }
    }
    #endif
    
    static var random: TraceOutput {
        switch Bool.random() {
        case true:
            return .entry(invocation: randomInvoke, method: nil, decorated: "helloWorld()", subLog: Bool.random())
        case false:
            return .exit(invocation: randomInvoke, method: nil, decorated: "peaceWorld()", subLog: Bool.random())
        }
    }
}
