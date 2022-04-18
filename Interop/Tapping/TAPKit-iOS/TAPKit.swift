//
//  TAPKit.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public class TAPKit : NSObject {
    @objc public static let sharedKit = TAPKit()
    
    @objc public static let log = TAPKitLog.sharedLog
    
    private var kitCentral : TAPKitCentral!
    
    private override init() {
        super.init()
        self.kitCentral = TAPKitCentral()
    }
}

extension TAPKit {
    // public interface
    
    
    
    @objc public func start() -> Void {
        self.kitCentral.start()
    }
    
    @objc public func addDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.kitCentral.add(delegate: delegate)
    }
    
    @objc public func removeDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.kitCentral.remove(delegate: delegate)
    }
    
    @objc public func setDefaultTAPInputMode(_ defaultMode:TAPInputMode, immediate:Bool) -> Void {
        self.kitCentral.setDefaultInputMode(defaultMode, immediate: immediate)
    }
    
    @objc public func setTAPInputMode(_ newMode:TAPInputMode, forIdentifiers identifiers : [String]? = nil) -> Void {
        self.kitCentral.setTAPInputMode(newMode, forIdentifiers: identifiers)
    }
    
    @objc public func getConnectedTaps() -> [String : String] {
        return self.kitCentral.getConnectedTaps()
    }
    
    @objc public func getTAPInputMode(forTapIdentifier identifier:String) -> TAPInputMode? {
        return self.kitCentral.getTAPInputMode(forTapIdentifier:identifier)
    }
    @objc public func vibrate(durations:Array<UInt16>, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.kitCentral.vibrate(durations: durations, forIdentifiers: identifiers)
    }
}
