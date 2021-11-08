import Foundation
import SceneKit

extension SCNView {
    func hitTestCodeSheet(with location: CGPoint,
                          _ mode: SCNHitTestSearchMode = .all,
                          _ mask: HitTestType = .all) -> [SCNHitTestResult] {
        return hitTest(
            location,
            options: [
                SCNHitTestOption.boundingBoxOnly: true,
                SCNHitTestOption.backFaceCulling: true,
                SCNHitTestOption.clipToZRange: true,
                SCNHitTestOption.ignoreChildNodes: false,
                SCNHitTestOption.categoryBitMask: mask.rawValue,
                SCNHitTestOption.searchMode: mode.rawValue
            ]
        )
    }
	
	func hitTestCodeGridTokens(with location: CGPoint,
							   _ mode: SCNHitTestSearchMode = .all,
							   _ mask: HitTestType = .codeGridToken) -> [SCNHitTestResult] {
		return hitTest(
			location,
			options: [
				SCNHitTestOption.boundingBoxOnly: true,
				SCNHitTestOption.backFaceCulling: true,
				SCNHitTestOption.clipToZRange: true,
				SCNHitTestOption.ignoreChildNodes: false,
				SCNHitTestOption.categoryBitMask: mask.rawValue,
				SCNHitTestOption.searchMode: mode.rawValue
			]
		)
	}
	
	func hitTest(location: CGPoint, _ mask: HitTestType = .codeGrid) -> [SCNHitTestResult] {
		return hitTest(
			location,
			options: [
				SCNHitTestOption.boundingBoxOnly: true,
				SCNHitTestOption.backFaceCulling: true,
				SCNHitTestOption.clipToZRange: true,
				SCNHitTestOption.ignoreChildNodes: false,
				SCNHitTestOption.categoryBitMask: mask.rawValue,
				SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
			]
		)
	}
}

struct HitTestType: OptionSet {
    let rawValue: Int

    static let codeSheet        = HitTestType(rawValue: 1 << 2)
    static let rootCodeSheet    = HitTestType(rawValue: 1 << 3)
    static let semanticTab      = HitTestType(rawValue: 1 << 4)
    static let directoryGroup   = HitTestType(rawValue: 1 << 5)
	
	static let codeGrid		    = HitTestType(rawValue: 1 << 6)
	static let codeGridToken    = HitTestType(rawValue: 1 << 7)
    static let codeGridSnapshot = HitTestType(rawValue: 1 << 8)

    static let all: HitTestType = [.codeSheet, .semanticTab, .rootCodeSheet, .directoryGroup, .codeGrid, .codeGridToken, .codeGridSnapshot]
}
