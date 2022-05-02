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
