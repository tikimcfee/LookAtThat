//
//  TAPDevice.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol TAPDeviceDelegate : AnyObject {
    func TAPIsReady(identifier:String, name:String, fw:Int)
    func TAPtapped(identifier:String, combination:UInt8)
    func TAPMoused(identifier:String, vX:Int16, vY:Int16, isMouse:Bool)
    func TAPFailed(identifier:String, name:String)
    func TAPRawSensorDataReceived(identifier:String, data:RawSensorData)
    func TAPAirGestured(identifier:String, gesture:TAPAirGesture)
    func TAPChangedAirGesturesState(identifier:String, isInAirGesturesState:Bool)
}

class TAPDevice : NSObject {
    private var peripheral : CBPeripheral!
    private weak var delegate : TAPDeviceDelegate?
    private var rx:CBCharacteristic?
    private var tx:CBCharacteristic?
    private var uiCommands:CBCharacteristic?
    private var airGestures : CBCharacteristic?
    private var fw:Int!
    private var neccessaryCharacteristics : [CBUUID : Bool] = [TAPCBUUID.characteristic__RX : false, TAPCBUUID.characteristic__TX : false, TAPCBUUID.characteristic__TAPData : false, TAPCBUUID.characteristic__FW : false]
    private var optionalCharacteristics : [CBUUID : Bool] = [TAPCBUUID.characteristic__MouseData : false, TAPCBUUID.characteristic__UICommands : false, TAPCBUUID.characteristic__AirGestures : false]
    
    var supportsMouse : Bool {
        get {
            return optionalCharacteristics[TAPCBUUID.characteristic__MouseData] == true
        }
    }
    
    var supportsAirGestures : Bool {
        get {
            return optionalCharacteristics[TAPCBUUID.characteristic__AirGestures] == true
        }
    }
    
    private(set) var isReady : Bool = false {
        willSet {
            if self.isReady == false && newValue == true {
                TAPKit.log.event(.info, message: "TAP \(self.identifier.uuidString),\(self.name ?? "NO_NAME_SET") is ready to use!")
                self.writeMode()
                self.delegate?.TAPIsReady(identifier: self.identifier.uuidString, name:self.name, fw: self.fw)
            }
        }
    }
    
    private(set) var identifier : UUID!
    private(set) var name : String!
    private(set) var mode : TAPInputMode!
    private(set) var modeEnabled : Bool!
    private(set) var isInAirGesturesState : Bool!
    
    override public var hash: Int {
        get {
            return self.identifier.hashValue
        }
    }
    
    
    init(peripheral p:CBPeripheral, delegate d:TAPDeviceDelegate) {
        super.init()
        self.mode = TAPInputMode.defaultMode()
        self.peripheral = p
        self.identifier = p.identifier
        if let n = p.name {
            self.name = n
        } else {
            self.name = ""
        }
        self.delegate = d
        self.fw = 0
        self.modeEnabled = true
        self.isInAirGesturesState = false
    }
    
    func makeReady() -> Void {
        self.peripheral?.delegate = self
        self.peripheral?.discoverServices([TAPCBUUID.service__TAP, TAPCBUUID.service__NUS, TAPCBUUID.service__DeviceInformation])
    }
    
    private func checkIfReady() -> Void {
        var allDiscovered = true
        for (_, value) in self.neccessaryCharacteristics {
            allDiscovered = allDiscovered && value
        }
        if self.name == "" {
            if let p = self.peripheral {
                if let n = p.name {
                    self.name = n
                }
            }
        }
        self.isReady = allDiscovered && self.name != "" && self.rx != nil && self.fw != 0
        
    }
    
    private func writeRX(_ data:Data) -> Void {
        if let rx = self.rx {
            if (peripheral.state == .connected) {
                let arr = [UInt8](data);
                if arr.count >= 3 {
                    let str = "\(arr)"
                    TAPKit.log.event(.info, message: "tap \(self.identifier.uuidString) writing mode data [\(str)]")
                }
                self.peripheral.writeValue(data, for: rx, type: .withoutResponse)
            } else {
                TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed writing mode: peripheral is not connected.")
            }
        }
    }
    
    func disableMode() -> Void {
        TAPKit.log.event(.info, message: "Disabled \(self.mode.title()) for tap identifier \(self.identifier.uuidString)")
        self.modeEnabled = false
        if let data = TAPInputMode.modeWhenDisabled().data() {
            self.writeRX(data)
        }
    }
    
    func enableMode() -> Void {
        TAPKit.log.event(.info, message: "Enabled [\(self.mode.title())] for tap identifier \(self.identifier.uuidString)")
        self.modeEnabled = true
        self.writeMode()
    }
    
    func writeMode() -> Void {
        if (self.modeEnabled) {
            if let data = self.mode.data() {
                self.writeRX(data)
            }
        }
    }
    
    func setNewMode(_ newMode:TAPInputMode) -> Void {
        TAPKit.log.event(.info, message: "New Mode Set: \(newMode.title()) for tap identifier \(self.identifier.uuidString)")
        self.mode = newMode
        self.writeMode()
    }
    
    func vibrate(_ durations:Array<UInt16>) -> Void {
        // New method - durations should be divided by 10.
        if let ch = self.uiCommands {
            if self.peripheral.state == .connected {
                var bytes = [UInt8].init(repeating: 0, count: 20)
                bytes[0] = 0
                bytes[1] = 2
                for i in 0..<min(18,durations.count) {
                    bytes[i+2] = UInt8( Double(durations[i])/10.0)
                }
                let data = Data(bytes)
                peripheral.writeValue(data, for: ch, type: .withoutResponse)

            }
        }
    }
    private func requestReadAirMouseMode() -> Void {
        if let ch = self.airGestures {
            if self.peripheral.state == .connected {
                var bytes = [UInt8].init(repeating: 0, count: 20)
                bytes[0] = 13
                let data = Data(bytes)
                peripheral.writeValue(data, for: ch, type: .withoutResponse)
            }
        }
    }
}

extension TAPDevice : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed discovered services: \(err.localizedDescription)")
            self.delegate?.TAPFailed(identifier: self.identifier.uuidString, name: self.name)
            return
        }
        if let services = peripheral.services {
            for service in services {
                var characteristicsToDiscover = [CBUUID]()
                for (characteristic, _) in self.neccessaryCharacteristics {
                    if let matchingService = TAPCBUUID.getService(for: characteristic) {
                        
                        if matchingService.uuidString == service.uuid.uuidString {
                            characteristicsToDiscover.append(characteristic)
                        }
                    }
                }
                for (characteristic, _) in self.optionalCharacteristics {
                    if let matchingService = TAPCBUUID.getService(for: characteristic) {
                        if matchingService.uuidString == service.uuid.uuidString {
                            characteristicsToDiscover.append(characteristic)
                        }
                    }
                }
                // Mouse is optional :
                
                if characteristicsToDiscover.count > 0 {
                    peripheral.discoverCharacteristics(characteristicsToDiscover, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed discovered characteristics: \(err.localizedDescription)")
            self.delegate?.TAPFailed(identifier: self.identifier.uuidString, name: self.name)
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if self.neccessaryCharacteristics.contains(where: { $0.key == characteristic.uuid}) {
                    self.neccessaryCharacteristics[characteristic.uuid] = true
                    if characteristic.uuid.uuidString == TAPCBUUID.characteristic__RX.uuidString {
                        self.rx = characteristic
                    } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TAPData.uuidString {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TX.uuidString {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__FW.uuidString {
                        self.peripheral.readValue(for: characteristic)
                    }
                    self.checkIfReady()
                } else if self.optionalCharacteristics.contains(where: { $0.key == characteristic.uuid}) {
                    self.optionalCharacteristics[characteristic.uuid] = true
                    if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__MouseData.uuidString) {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    } else if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__UICommands.uuidString) {
                        self.uiCommands = characteristic
                    } else if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__AirGestures.uuidString) {
                        self.airGestures = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        self.requestReadAirMouseMode()
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            if characteristic.uuid.uuidString == TAPCBUUID.characteristic__RX.uuidString {
                TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed writing input mode: \(err.localizedDescription)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__FW.uuidString) {
            if let value = characteristic.value {
                if let fw_ = VersionNumber.data2Int(data: value) {
                    self.fw = fw_
                }
            }
            self.checkIfReady()
        } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TAPData.uuidString {
            if let value = characteristic.value {
                let bytes = [UInt8](value)
                if let first = bytes.first {
                    if first > 0 && first <= 31 {
                        if (self.isInAirGesturesState)  {
                            if let gesture = TAPAirGestureHelper.tapToAirGesture(first) {
                                self.delegate?.TAPAirGestured(identifier: self.identifier.uuidString, gesture: gesture)
                            }
                        } else {
                            self.delegate?.TAPtapped(identifier: self.identifier.uuidString, combination: first)
                        }
                    }
                }
                
            }
        } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__MouseData.uuidString {
            
            if let value = characteristic.value {
                let bytes : [UInt8] = [UInt8](value)
                if bytes.count >= 10 {
                    if (bytes[0] == 0 ) {
                        self.delegate?.TAPMoused(identifier: self.identifier.uuidString, vX: (Int16)(bytes[2]) << 8 | (Int16)(bytes[1]), vY: (Int16)(bytes[4]) << 8 | (Int16)(bytes[3]), isMouse: bytes[9] == 1)
                    }
                }
            }
        } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TX.uuidString {
            if self.mode.type == TAPInputMode.kRawSensor {
                if let value = characteristic.value {
                    if let sensitivity = self.mode.sensitivity {
                        RawSensorDataParser.parseWhole(data: value , sensitivity: sensitivity, onMessageReceived: { (rawSensorData) in
                            self.delegate?.TAPRawSensorDataReceived(identifier: self.identifier.uuidString, data: rawSensorData)
                        })
                    }
                    
                }
                
            }
        } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__AirGestures.uuidString {
            if let value = characteristic.value {
                let bytes : [UInt8] = [UInt8](value)
                if bytes.count > 0 {
                    let first = bytes[0]
                    if (first != 20) {
                        if let gesture = TAPAirGesture(rawValue: Int(first)) {
                            self.delegate?.TAPAirGestured(identifier: self.identifier.uuidString, gesture: gesture)
                        }
                    } else {
                        if bytes.count > 1 {
                            self.isInAirGesturesState = bytes[1] == 1
                            self.delegate?.TAPChangedAirGesturesState(identifier: self.identifier.uuidString, isInAirGesturesState: self.isInAirGesturesState)
                        }
                    }
                }
            }
        }
    }
}
