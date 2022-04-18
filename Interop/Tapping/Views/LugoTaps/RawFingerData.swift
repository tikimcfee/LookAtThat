//
//  RawFingerData.swift
//  TAPKit-Example
//
//  Created by Ivan Lugo on 10/4/21.
//  Copyright © 2021 Shahar Biran. All rights reserved.
//

import Foundation

extension Fingers {
	var rawSensorID: Int {
		switch self {
			case .thumb: return RawSensorData.iDEV_THUMB
			case .index: return RawSensorData.iDEV_INDEX
			case .middle: return RawSensorData.iDEV_MIDDLE
			case .ring: return RawSensorData.iDEV_RING
			case .pinky: return RawSensorData.iDEV_PINKY
		}
	}
}

enum IMU: String, CaseIterable {
	case gyro
	case accelerometer
	
	var rawIMUID: Int {
		switch self {
			case .gyro: 
				return RawSensorData.iIMU_GYRO
			case .accelerometer: 
				return RawSensorData.iIMU_ACCELEROMETER
		}
	}
}

class RawSensorState {
	
	private var fingerPositions: [Fingers: LList<Point3>] = [:]
	private var imuPositions: [IMU: LList<Point3>] = [:]
	private var addQueue = DispatchQueue(label: "RawSensorInput", qos: .userInitiated)
	
	init() {
		Fingers.allCases.forEach { _ = fingerList($0) }
		IMU.allCases.forEach { _ = imuList($0) }
	}
	
	func update(data: RawSensorData) {
		addQueue.async { [data] in
			self.doUpdate(data)
		}
	}
	
	private func doUpdate(_ data: RawSensorData) { 
		switch data.type {
			case .Device:
				Fingers.allCases.forEach {
					if let rawPoint = data.getPoint(for: $0.rawSensorID) {
						fingerList($0).append(rawPoint)
					}
				}
			case .IMU:
				IMU.allCases.forEach {
					if let rawPoint = data.getPoint(for: $0.rawIMUID) {
						imuList($0).append(rawPoint)
					}
				}
			case .None:
				break
		}
	}
}

extension RawSensorState {
	func readFingers(_ reader: (Fingers, Point3) -> Void) {
		Fingers.allCases.forEach { finger in
			fingerPositions[finger]?.forEach { pointPosition in 
				reader(finger, pointPosition)
			}
		}
	}
	
	func readIMU(_ reader: (IMU, Point3) -> Void) {
		IMU.allCases.forEach { imu in
			imuPositions[imu]?.forEach { pointPosition in 
				reader(imu, pointPosition)
			}
		}
	}
	
	func makeFingerIterators(_ reader: (Fingers, LList<Point3>.Iterator) -> Void) {
		Fingers.allCases.forEach { finger in
			reader(finger, fingerList(finger).makeIterator())
		}
	}
	
	func makeIMUIterators(_ reader: (IMU, LList<Point3>.Iterator) -> Void) {
		IMU.allCases.forEach { imu in
			reader(imu, imuList(imu).makeIterator())
		}
	}

	private func fingerList(_ finger: Fingers) -> LList<Point3> {
		let list = fingerPositions[finger] ?? LList()
		fingerPositions[finger] = list
		return list
	}
	
	private func imuList(_ imu: IMU) -> LList<Point3> {
		let list = imuPositions[imu] ?? LList()
		imuPositions[imu] = list
		return list
	}
}
