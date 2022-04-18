//
//  TAPKitCentral.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class TAPKitCentral : NSObject {
    
    private var centralManager : CBCentralManager!
    private var pending : Set<CBPeripheral>!
    private var taps : Set<TAPDevice>!
    private var started : Bool!
    private var isBluetoothOn : Bool!
    
    private var delegatesController : TAPKitDelegatesController!
    private var connectionTimer : Timer?
    private var modeTimer : Timer?
    private var defaultInputMode : TAPInputMode!
    
    private var appActive : Bool = true
    
    override init() {
        super.init()
        
        self.defaultInputMode = TAPInputMode.controller()
        self.delegatesController = TAPKitDelegatesController()
        self.isBluetoothOn = false
        self.pending = Set<CBPeripheral>()
        self.taps = Set<TAPDevice>()
        self.setupObservers()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.started = false
        self.centralManagerDidUpdateState(self.centralManager)
    }
    
    #if os(macOS)
    let activeName = NSApplication.didBecomeActiveNotification
    let resignName = NSApplication.willResignActiveNotification
    #else
    let activeName = UIApplication.didBecomeActiveNotification
    let resignName = UIApplication.willResignActiveNotification
    #endif
    
    private func setupObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: activeName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: resignName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)   
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        self.appActive = true
        TAPKit.log.event(.info, message: "appDidBecomeActive notification")
        self.taps.forEach({
            $0.enableMode()
        })
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        self.appActive = false
        TAPKit.log.event(.info, message: "appWillResignActive notification")
        self.taps.forEach({
            $0.disableMode()
        })
    }
    
    @objc func appWillTerminate(notification:NSNotification) -> Void {
        TAPKit.log.event(.info, message: "appWillTerminate notification")
        self.taps.forEach({
            $0.disableMode()
        })
    }
    
    
    deinit {
        self.stopConnectionTimer()
        self.stopModeTimer()
    }
    
    private func stopConnectionTimer() -> Void {
        self.connectionTimer?.invalidate()
        TAPKit.log.event(.info, message: "connection timer stopped")
    }
    
    private func startConnectionTimer() -> Void {
        self.stopConnectionTimer()
        self.connectionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(connectionTimerTick(timer:)), userInfo: nil, repeats: true)
        TAPKit.log.event(.info, message: "connection timer started")
        self.connectionTimerTick(timer: nil)
    }
    
    private func startModeTimer() -> Void {
        self.stopModeTimer()
        self.modeTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(modeTimerTick(timer:)), userInfo: nil, repeats: true)
        TAPKit.log.event(.info, message: "mode timer started")
        self.modeTimerTick(timer: nil)
    }
    
    private func stopModeTimer() -> Void {
        self.modeTimer?.invalidate()
        TAPKit.log.event(.info, message: "mode timer stopped")
    }
    
    private func bluetoothIsOff() -> Void {
        if (self.isBluetoothOn) {
            TAPKit.log.event(.info, message: "Bluetooth poweredOff")
            self.isBluetoothOn = false
            self.pending.removeAll()
            self.taps.removeAll()
            self.stopConnectionTimer()
            
        }
    }
    
    private func bluetoothIsOn() -> Void {
        if (!self.isBluetoothOn) {
            TAPKit.log.event(.info, message: "Bluetooth poweredOn")
            self.isBluetoothOn = true
            if (self.started) {
                self.start()
            }
        }
    }
    
    private func isPending(_ peripheral:CBPeripheral) -> Bool {
        return self.pending.contains(peripheral)
    }
    
    private func isConnected(_ peripheral:CBPeripheral) -> Bool {
        return self.taps.contains(where: { $0.identifier == peripheral.identifier })
    }
    
    private func tapIndex(_ peripheral:CBPeripheral) -> Set<TAPDevice>.Index? {
        return self.taps.firstIndex(where: { $0.identifier == peripheral.identifier})
    }
    
    private func isNewPeripheral(_ peripheral:CBPeripheral) -> Bool {
        return !self.isPending(peripheral) && !self.isConnected(peripheral)
    }
    
    @objc func connectionTimerTick(timer:Timer?) -> Void {
        let connectedPeripherals = self.centralManager.retrieveConnectedPeripherals(withServices: [TAPCBUUID.service__TAP])
        for peripheral in connectedPeripherals {
            if (self.isNewPeripheral(peripheral)) {
                self.pending.insert(peripheral)
                TAPKit.log.event(.info, message: "connecting to a new tap \(peripheral.identifier.uuidString), \(String.init(describing: peripheral.name))")
                self.centralManager.connect(peripheral, options: nil)
                
            }
        }
    }
    
    @objc func modeTimerTick(timer:Timer?) -> Void {
        self.taps.forEach({ $0.writeMode()})
    }
}

extension TAPKitCentral : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn : self.bluetoothIsOn()
        default : self.bluetoothIsOff()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.pending.remove(peripheral)
        TAPKit.log.event(.info, message: "central manager connected to \(peripheral.identifier), initializing tap...")
        let tap = TAPDevice(peripheral: peripheral, delegate: self)
        self.taps.insert(tap)
        tap.makeReady()
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            self.taps.remove(at: index)
        }
        TAPKit.log.event(.error, message: "central manager failed connecting to \(peripheral.identifier)")
        self.delegatesController.tapFailedToConnect(withIdentifier: peripheral.identifier.uuidString, name: peripheral.name != nil ? peripheral.name! : "")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            TAPKit.log.event(.info, message: "disconnected \(peripheral.identifier)")
            self.delegatesController.tapDisconnected(withIdentifier: self.taps[index].identifier.uuidString)
            self.taps.remove(at: index)
        }
    }
}

extension TAPKitCentral : TAPDeviceDelegate {
    func TAPIsReady(identifier: String, name: String, fw:Int) {
        if let index = self.taps.firstIndex(where: { $0.identifier.uuidString == identifier }) {
            if self.appActive {
                self.taps[index].setNewMode(self.defaultInputMode)
                self.taps[index].writeMode()
            }
        }
        self.delegatesController.tapConnected(withIdentifier: identifier, name: name, fw:fw)
    }
    
    func TAPtapped(identifier: String, combination: UInt8) {
        self.delegatesController.tapped(identifier: identifier, combination: combination)
    }
    
    func TAPFailed(identifier: String, name: String) {
        self.delegatesController.tapFailedToConnect(withIdentifier: identifier, name: name)
        if let index = self.taps.firstIndex(where: { $0.identifier.uuidString == identifier}) {
            self.taps.remove(at: index)
        }
    }
    
    func TAPMoused(identifier: String, vX: Int16, vY: Int16, isMouse:Bool) {
        self.delegatesController.moused(identifier: identifier, velocityX: vX, velocityY: vY, isMouse: isMouse)
    }
    
    func TAPRawSensorDataReceived(identifier: String, data: RawSensorData) {
        self.delegatesController.rawSensorDataReceived(identifier: identifier, data: data)
    }
    
    func TAPAirGestured(identifier: String, gesture: TAPAirGesture) {
        self.delegatesController.tapAirGestured(identifier: identifier, gesture: gesture)
    }
    
    func TAPChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool) {
        self.delegatesController.tapChangedAirGesturesState(identifier: identifier, isInAirGesturesState: isInAirGesturesState)
    }
    
}

extension TAPKitCentral {
    // Public
    func start() -> Void {
        self.pending.removeAll()
        self.taps.removeAll()
        self.started = true
        if (self.isBluetoothOn) {
            self.startConnectionTimer()
            self.startModeTimer()
        }
    }
    
    func add(delegate:TAPKitDelegate) -> Void {
        self.delegatesController.add(delegate)
    }
    
    func remove(delegate:TAPKitDelegate) -> Void {
        self.delegatesController.remove(delegate)
    }
    
    func setDefaultInputMode(_ mode:TAPInputMode, immediate:Bool) -> Void {
        self.defaultInputMode = mode
        if immediate {
            self.taps.forEach({
                $0.setNewMode(mode)
            })
        }
    }
    
    private func performTAPAction(on identifiers:[String]?, action:((TAPDevice)->Void)) -> Void {
        if let ids = identifiers {
            ids.forEach({ identifier in
                if let index = self.taps.firstIndex(where: { tapdevice in
                    tapdevice.identifier.uuidString == identifier
                }) {
                    action(self.taps[index])
//                    self.taps[index].setNewMode(newMode)
                }
            })
        } else {
            self.taps.forEach({
                action($0)
//                $0.setNewMode(newMode)
            })
        }
    }
    
    func setTAPInputMode(_ newMode:TAPInputMode, forIdentifiers identifiers : [String]?) -> Void {
        self.performTAPAction(on: identifiers, action: { tap in
            tap.setNewMode(newMode)
        })
    }
    
    func vibrate(durations:Array<UInt16>, forIdentifiers identifiers : [String]?) -> Void {
        self.performTAPAction(on: identifiers, action: { tap in
            tap.vibrate(durations)
        })
        }
    
    func getConnectedTaps() -> [String : String] {
        var res = [String:String]()
        self.taps.forEach({
            if $0.isReady {
                res[$0.identifier.uuidString] = $0.name
            }
            
        })
        return res
    }
    
    func getTAPInputMode(forTapIdentifier identifier:String) -> TAPInputMode? {
        if let index = self.taps.firstIndex(where: { $0.identifier.uuidString == identifier }) {
            return self.taps[index].mode
        }
        return nil
    }
}

