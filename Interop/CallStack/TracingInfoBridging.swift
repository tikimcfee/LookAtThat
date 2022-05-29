//
//  TracedInfoBridging.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if !TARGETING_SUI && !os(iOS)
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

// MARK: - Signature cleaning

extension TraceOutput {
    var callComponents: (callPath: String, allComponents: [String]) {
        return CallStackParsing.callComponents(from: signature)
    }
}

extension TraceOutput {
    static let EntryName = "-> "
    static let ExitName =  "<- "
    
    static func lineIsExit(_ traceLine: TraceLine) -> Bool {
        return !lineIsEntry(traceLine)
    }
    
    static func lineIsEntry(_ traceLine: TraceLine) -> Bool {
        switch traceLine.entryExitName {
        case EntryName:
            return true
        default:
            return false
        }
    }
    
    var entryExitName: String {
        switch self {
        case .entry: return Self.EntryName
        case .exit:  return Self.ExitName
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
    
    #if TARGETING_SUI || os(iOS)
    static var randomInvoke: String { "" }
    var signature: String { decorated }
    #else
    static var randomInvoke: SwiftTrace.Swizzle.Invocation {
        SwiftTrace.Swizzle.Invocation(
            stackDepth: 10,
            swizzle: SwiftTrace.Swizzle(
                name: "TestSwizzle",
                original: OpaquePointer(bitPattern: 69420)
            )!,
            returnAddress: UnsafeRawPointer(bitPattern: 69)!,
            stackPointer: UnsafeMutablePointer<UInt64>(bitPattern: 420)!
        )
    }
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

extension TraceLine {
    static var random: TraceLine {
        return TraceLine(
            entryExitName: Bool.random() ? "-> " : "<- ",
            signature: randomSignatures.randomElement()!,
            threadName: Thread.current.threadName,
            queueName: currentQueueName()
        )
    }
    static var randomSignatures: [String] = {
        let baseChars = "qwertyuiopasdfghjklzxcvbnm"
        let allChars = "\(baseChars)\(baseChars.uppercased())"
        let set = [
            "helloWorld()",
            "peaceWorld()",
            "bungleMuk()",
            "reticulateAllSplines(butNot: )",
            "splineOnlyWhenGrunked(outside: withExtra: seeking: )",
            "checkingTheOutsideFPAC(includingSecure: )",
            "makeMoney(buyMedicine: )",
            "ensure(butNotAlways: )",
        ]
        return (0..<100).reduce(into: [String]()) { result, _ in
            if Bool.random() {
                let randomChars = (0..<50)
                    .filter { _ in Bool.random() }
                    .compactMap { _ in allChars.randomElement() }
                result.append(String(randomChars) + "()")
            } else {
                result.append(set.randomElement()!)
            }
        }
    }()
}

extension TraceLine {
    static let fieldSeparator = "|@@@|"
    static let expectedFields = 4
    
    func serialize() -> String {
        return [
            entryExitName,
            signature,
            threadName,
            queueName
        ].joined(separator: Self.fieldSeparator)
    }
    
    static func deserialize(
        traceLine: String
    ) -> TraceLine? {
        let splitLine = traceLine.components(separatedBy: fieldSeparator)
        guard splitLine.indices == (0..<expectedFields) else { return nil }
        return TraceLine(
            entryExitName: splitLine[0],
            signature: splitLine[1],
            threadName: splitLine[2],
            queueName: splitLine[3]
        )
    }
}
