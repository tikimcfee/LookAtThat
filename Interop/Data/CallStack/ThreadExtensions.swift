//
//  ThreadTracing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

extension Thread {
    private static let threadNameStorage = ConcurrentDictionary<Thread, String>()
    
    var threadName: String {
        if let name = Self.threadNameStorage[self] { return name }
        let threadName: String
        if isMainThread {
            threadName = "main"
        } else if let directName = name, !directName.isEmpty {
            threadName = directName
        } else {
            let info = ThreadInfoExtract.from(description)
            threadName = info.number
        }
        
        Self.threadNameStorage[self] = threadName
        return threadName
    }
}
