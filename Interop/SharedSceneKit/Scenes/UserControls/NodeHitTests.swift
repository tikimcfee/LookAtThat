import Foundation
import SceneKit

extension SCNView {
	
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
