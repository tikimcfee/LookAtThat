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
                SCNHitTestOption.ignoreChildNodes: false,
                SCNHitTestOption.categoryBitMask: HitTestType.all.rawValue,
                SCNHitTestOption.searchMode: mode.rawValue
            ]
        )
    }
}

struct HitTestType: OptionSet {
    let rawValue: Int

    static let codeSheet    = HitTestType(rawValue: 1 << 2)
    static let semanticTab  = HitTestType(rawValue: 1 << 3)

    static let all: HitTestType = [.codeSheet, .semanticTab]
}
