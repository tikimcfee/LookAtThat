import Foundation
import SceneKit

extension SCNNode {
    var xwireNode: WireNode { WireNode.from(self, isContainer: false) }
    var xcontainerWireNode: WireNode { WireNode.from(self, isContainer: true) }
}
