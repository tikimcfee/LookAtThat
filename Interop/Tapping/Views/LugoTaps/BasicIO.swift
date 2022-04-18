//
//  IO.swift
//  IOTAPS
//
//  Created by Ivan Lugo on 10/5/21.
//  Copyright © 2021 Shahar Biran. All rights reserved.
//

import Foundation

extension URL {
	var hasData: Bool {
		let attributes = try? FileManager.default.attributesOfItem(atPath: path) as NSDictionary
		let size = attributes?.fileSize() ?? 0
		return size > 0
	}
}
