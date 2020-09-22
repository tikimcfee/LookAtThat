import Foundation
import SceneKit

extension SCNView {
    func hitTestCodeSheet(with location: CGPoint,
                          _ mode: SCNHitTestSearchMode = .all) -> [SCNHitTestResult] {
        return hitTest(
            location,
            options: [
                SCNHitTestOption.boundingBoxOnly: true,
                SCNHitTestOption.backFaceCulling: true,
                SCNHitTestOption.clipToZRange: true,
                SCNHitTestOption.categoryBitMask: HitTestType.codeSheet,
                SCNHitTestOption.searchMode: mode.rawValue
            ]
        )
    }
}

struct HitTestType  {
    static let codeSheet: Int = 0x1 << 1
}
