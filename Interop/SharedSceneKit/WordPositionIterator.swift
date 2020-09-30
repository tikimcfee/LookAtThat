import Foundation
import SceneKit

class WordPositionIterator {
    let linesPerBlock = CGFloat(WORD_FONT_POINT_SIZE + LINE_MARGIN_HEIGHT)
    let wordYSemaphore = DispatchSemaphore(value: 1)
    var wordY = CGFloat(0)

    func reset(_ to: CGFloat = 0) {
        wordY = to
    }

    func nextLineY() -> CGFloat {
        let next = wordY
        wordY -= linesPerBlock
        return next
    }

    func nextPosition() -> SCNVector3 {
        return SCNVector3(x: -100, y: nextLineY().vector, z: -25)
    }

    func wordIndicesForWordCount(_ words: Int) -> [SCNVector3] {
        wordYSemaphore.wait()
        defer { wordYSemaphore.signal() }
        return (0..<words).map{ _ in SCNVector3(-100, nextLineY(), -25) }
    }
}
