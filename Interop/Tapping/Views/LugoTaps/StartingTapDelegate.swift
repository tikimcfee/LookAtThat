//
//  StartingTapDelegate.swift
//  IOTAPS
//
//  Created by Ivan Lugo on 10/5/21.
//  Copyright © 2021 Shahar Biran. All rights reserved.
//

import Foundation

typealias TapUpdates = ([Fingers]) -> Void

class StartingTapDelegate: TAPKitDelegate {
	typealias PointIterator = LList<Point3>.Iterator
	
	var tapUpdates: TapUpdates?
	
	private let raw = RawSensorState()
	private let fileQueue = DispatchQueue(label: "RawDataWriter", qos: .background)
	
	private lazy var fingerIterators: [Fingers: PointIterator] = {
		var iterators = [Fingers: PointIterator]()
		raw.makeFingerIterators { finger, iterator in 
			iterators[finger] = iterator
		}
		return iterators
	}()
	
	private lazy var imuIterators: [IMU: PointIterator] = {
		var iterators = [IMU: PointIterator]()
		raw.makeIMUIterators { imu, iterator in 
			iterators[imu] = iterator
		}
		return iterators
	}()
	
	func centralBluetoothState(poweredOn: Bool) {
		print("Bluetooth state changed: powerxeeaaareedOn=\(poweredOn)")
	}
	
	func tapped(identifier: String, combination: UInt8) {
		// Called when a user tap, only when the TAP device is in controller mode.
		print("TAP \(identifier) tapped combination: \(combination)")        
		let lugoFingers = Fingers.fromIntCombination(combination)
		print("+++ lugo says: \(lugoFingers)")
		tapUpdates?(lugoFingers)
	}
	
	func tapDisconnected(withIdentifier identifier: String) {
		print("TAP \(identifier) disconnected.")
	}
	
	func tapConnected(withIdentifier identifier: String, name: String) {
		print("TAP \(identifier), \(name) connected!")
	}
	
	func tapFailedToConnect(withIdentifier identifier: String, name: String) {
		print("TAP \(identifier), \(name) failed to connect!")
	}
	
	func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse: Bool) {
		// Added isMouse parameter:
		// A boolean that determines if the TAP is really using the mouse (true) or is it a dummy mouse movement (false)
		
		// Getting an event for when the Tap is using the mouse, called only when the Tap is in controller mode.
		// Since iOS doesn't support mouse - You can implement it in your app using the parameters of this function.
		// velocityX : get the amount of movement for X-axis.
		// velocityY : get the amount of movement for Y-axis.
	}
	
	func rawSensorDataReceived(identifier: String, data: RawSensorData) {
		raw.update(data: data)
		updateRawFiles()
	}
	
	private func updateRawFiles() {
		fileQueue.async {
			Fingers.allCases.forEach { finger in
				var iterator = self.fingerIterators[finger]
				while let point = iterator?.next() {
					let newLine = "\(finger.rawValue) \(point.x) \(point.y) \(point.z)\n"
					print(newLine)
//					self.fingerDirectStore.appendText(newLine)
				}
				self.fingerIterators[finger] = iterator // need to reset iterator to keep state
			}
			IMU.allCases.forEach { imu in
				var iterator = self.imuIterators[imu]
				while let point = iterator?.next() {
					let newLine = "\(imu.rawValue) \(point.x) \(point.y) \(point.z)\n"
					print(newLine)
//					self.imuDirectStore.appendText(newLine)
				}
				self.imuIterators[imu] = iterator // need to reset iterator to keep state
			}
		}
	}
	
	func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
		switch (gesture) {
			case .OneFingerDown : print("Air Gestured: One Finger Down")
			case .OneFingerLeft : print("Air Gestured: One Finger Left")
			case .OneFingerUp : print("Air Gestured: One Finger Up")
			case .OnefingerRight : print("Air Gestured: One Finger Right")
			case .TwoFingersDown : print("Air Gestured: Two Fingers Down")
			case .TwoFingersLeft : print("Air Gestured: Two Fingers Left")
			case .TwoFingersUp : print("Air Gestured: Two Fingers Up")
			case .TwoFingersRight : print("Air Gestured: Two Fingers Right")
			case .IndexToThumbTouch : print("Air Gestured: Index finger tapping the Thumb")
			case .MiddleToThumbTouch : print("Air Gestured: Middle finger tapping the Thumb")
		}
	}
	
	func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool) {
		print("Tap is in Air Gesture State: \(isInAirGesturesState)")
	}
}
