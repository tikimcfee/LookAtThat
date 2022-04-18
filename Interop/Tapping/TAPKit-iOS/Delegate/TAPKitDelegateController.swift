//
//  TAPKitDelegatesController.swift
//  TAPKit
//
//  Created by Shahar Biran on 25/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

@objc public protocol TAPKitDelegate : AnyObject {
    @objc optional func centralBluetoothState(poweredOn:Bool) -> Void
    @objc optional func tapConnected(withIdentifier identifier:String, name:String, fw:Int)
    @objc optional func tapDisconnected(withIdentifier identifier:String)
    @objc optional func tapFailedToConnect(withIdentifier identifier:String, name:String)
    @objc optional func tapped(identifier:String, combination:UInt8)
    @objc optional func moused(identifier:String, velocityX:Int16, velocityY:Int16, isMouse:Bool)
    @objc optional func rawSensorDataReceived(identifier:String, data:RawSensorData)
    @objc optional func tapChangedAirGesturesState(identifier:String, isInAirGesturesState:Bool)
    @objc optional func tapAirGestured(identifier:String, gesture:TAPAirGesture)
}

class TAPKitDelegateWeakRef {
    
    private weak var ref: TAPKitDelegate?
    
    init(_ ref: TAPKitDelegate) {
        self.ref = ref
    }
    
    func get() -> TAPKitDelegate? {
        return self.ref
    }
    
    func isAlive() -> Bool {
        return self.ref != nil
    }
}

class TAPKitDelegatesController {
    private var delegates : [TAPKitDelegateWeakRef]
    
    init() {
        self.delegates = [TAPKitDelegateWeakRef]()
    }
    
    private func removeNullReferences() -> Void {
        self.delegates = self.delegates.filter({ $0.isAlive() })
    }
    
    func add(_ delegate:TAPKitDelegate) -> Void {
        self.removeNullReferences()
        if (!self.delegates.contains(where: { $0.get() === delegate })) {
            
            self.delegates.append(TAPKitDelegateWeakRef(delegate))
        }
    }
    
    func remove(_ delegate:TAPKitDelegate) -> Void {
        self.removeNullReferences()
        self.delegates = self.delegates.filter({ $0.get() !== delegate })
    }
    
    func get() -> [TAPKitDelegate] {
        self.removeNullReferences()
        return self.delegates.filter({ $0.isAlive()}).map({ $0.get()!})
    }
}

extension TAPKitDelegatesController : TAPKitDelegate {
    func tapDisconnected(withIdentifier identifier: String) {
        self.get().forEach({
            $0.tapDisconnected?(withIdentifier: identifier)
        })
    }
    
    func tapConnected(withIdentifier identifier: String, name: String, fw:Int) {
        self.get().forEach({
            $0.tapConnected?(withIdentifier: identifier, name: name, fw:fw)
        })
    }
    
    func tapFailedToConnect(withIdentifier identifier: String, name: String) {
        self.get().forEach({
            $0.tapFailedToConnect?(withIdentifier: identifier, name: name)
        })
    }

    func tapped(identifier: String, combination: UInt8) {
        self.get().forEach({
            $0.tapped?(identifier: identifier, combination: combination)
        })
    }
    
    func centralBluetoothState(poweredOn: Bool) {
        self.get().forEach({
            $0.centralBluetoothState?(poweredOn: poweredOn)
        })
    }
    
    func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse:Bool) {
        self.get().forEach({
            $0.moused?(identifier: identifier, velocityX: velocityX, velocityY: velocityY, isMouse: isMouse)
        })
    }
    
    func rawSensorDataReceived(identifier: String, data: RawSensorData) {
        self.get().forEach({
            $0.rawSensorDataReceived?(identifier: identifier, data: data)
        })
    }

    func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool) {
        self.get().forEach({
            $0.tapChangedAirGesturesState?(identifier: identifier, isInAirGesturesState: isInAirGesturesState)
        })
    }
    
    func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
        self.get().forEach({
            $0.tapAirGestured?(identifier: identifier, gesture: gesture)
        })
    }
    
     
}

