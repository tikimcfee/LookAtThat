import Foundation
import SceneKit

extension SCNView {
    func hitTestCodeSheet(with location: CGPoint) -> [SCNHitTestResult] {
        return hitTest(
            location,
            options: [
                SCNHitTestOption.boundingBoxOnly: true,
                SCNHitTestOption.backFaceCulling: true,
                SCNHitTestOption.clipToZRange: true,
                SCNHitTestOption.categoryBitMask: HitTestType.codeSheet,
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
            ]
        )
    }
}

struct HitTestType  {
    static let codeSheet: Int = 0x1 << 1
}
