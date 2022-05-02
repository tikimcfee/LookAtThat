//
//  TraceLine.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

protocol TraceLineType {
    var entryExitName: String { get }
    var callPath: String { get }
    var callPathComponents: [String] { get }
    var signature: String { get }
    var threadName: String { get }
    var queueName: String { get }
}

class TraceLine: TraceLineType, Identifiable {
    let entryExitName: String
    let signature: String
    let threadName: String
    let queueName: String
    
    var callPath: String { callComponentsParsed.callPath }
    var callPathComponents: [String] { callComponentsParsed.allComponents }
    private lazy var callComponentsParsed: (callPath: String, allComponents: [String]) = {
        CallStackParsing.callComponents(from: signature)
    }()
    
    static var missing: TraceLine {
        TraceLine(entryExitName: "?? ", signature: "No signature found", threadName: "NoThread", queueName: "NoQueue")
    }
    
    init(entryExitName: String,
         signature: String,
         threadName: String,
         queueName: String) {
        self.entryExitName = entryExitName
        self.signature = signature
        self.threadName = threadName
        self.queueName = queueName
    }
}

extension TraceLine: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(entryExitName)
        hasher.combine(signature)
        hasher.combine(threadName)
        hasher.combine(queueName)
    }
    
    static func == (_ left: TraceLine, _ right: TraceLine) -> Bool {
        return left.entryExitName == right.entryExitName
            && left.signature == right.signature
            && left.threadName == right.threadName
            && left.queueName == right.queueName
    }
}
