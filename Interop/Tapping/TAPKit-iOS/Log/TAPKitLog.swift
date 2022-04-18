//
//  TAPKitLog.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

@objc public enum TAPKitLogEvent : Int {
    case warning = 0
    case error = 1
    case info = 2
    case fatal = 3
}

@objc public class TAPKitLog : NSObject {
    
    @objc public static let sharedLog = TAPKitLog()
    
    private override init() {
        super.init()
    }
    
    private var enabledEvents : [TAPKitLogEvent : Bool] = [.warning : true, .error : true, .info : true, .fatal : true]
    
    private let dateFormat = "yyyy-MM-dd hh:mm:ss(SSS)" // Use your own
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private func dateString() -> String {
        return dateFormatter.string(from: Date())
    }
    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    private func eventString(_ event:TAPKitLogEvent) -> String {
        switch event {
        case .error : return "ERROR"
        case .fatal : return "FATAL"
        case .info : return "info"
        case .warning : return "warning"
        }
    }
    
    var runningLogs = [String]()
    
    func event(_ e:TAPKitLogEvent, message:String, fileName : String = #file, line:Int = #line, function:String = #function) {
        if let enabled = enabledEvents[e] {
            if (enabled) {
                let log = "[\(dateString())] TAPKit \(eventString(e)) # \(message) @ \(sourceFileName(filePath: fileName)):\(function)(\(line))"
                runningLogs.insert(log, at: 0)
                print(log)
            }
        }
    }
    
    @objc public func enable(event:TAPKitLogEvent) -> Void {
        enabledEvents[event] = true
    }

    @objc public func disable(event:TAPKitLogEvent) -> Void {
        enabledEvents[event] = false
      
    }

    @objc public func disableAllEvents() -> Void {
        for (key, _) in enabledEvents {
            enabledEvents[key] = false
        }
    }

    @objc public func enableAllEvents() -> Void {
        for (key, _) in enabledEvents {
            enabledEvents[key] = true
        }
    }
    
}
