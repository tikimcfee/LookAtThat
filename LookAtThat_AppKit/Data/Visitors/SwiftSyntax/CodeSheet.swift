import Foundation
import SceneKit

class CodeSheet {

    var children = [CodeSheet]()
    weak var parent: CodeSheet?

    lazy var sheetName = UUID().uuidString
    lazy var allLines = [SCNNode]()
    lazy var iteratorY = WordPositionIterator()

    lazy var containerNode: SCNNode = {
        let container = SCNNode()
        container.addChildNode(pageGeometryNode)
        pageGeometryNode.categoryBitMask = HitTestType.codeSheet
        pageGeometryNode.geometry = pageGeometry
        return container
    }()

    lazy var pageGeometryNode = SCNNode()

    lazy var pageGeometry: SCNBox = {
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }()

    lazy var lastLine: SCNNode = {
        // The scene geometry at the end is off by a line. This will probably be an issue at some point.
        let line = SCNNode()
        line.position = SCNVector3(0, iteratorY.nextLineY(), PAGE_EXTRUSION_DEPTH)
        containerNode.addChildNode(line)
        return line
    }()

    init(parent: CodeSheet? = nil) {
        self.parent = parent
    }
}

extension CodeSheet {
    func newlines(_ count: Int) {
        for _ in 0..<count {
            setNewLine()
        }
    }

    private func setNewLine() {
        let newLine = SCNNode()
        newLine.position = lastLine.position.translated(
            dY: -iteratorY.linesPerBlock
        )
        allLines.append(newLine)
        lastLine = newLine
        containerNode.addChildNode(newLine)
    }

    func sizePageToContainerNode() {
        pageGeometry.width = containerNode.lengthX
        pageGeometry.height = containerNode.lengthY
        let centerY = -pageGeometry.height / 2
        let centerX = pageGeometry.width / 2
        pageGeometryNode.position.y = centerY
        pageGeometryNode.position.x = centerX
        containerNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY, 0);
    }

    func spawnChild() -> CodeSheet {
        let codeSheet = CodeSheet(parent: self)
        containerNode.addChildNode(codeSheet.containerNode)
        children.append(codeSheet)
        return codeSheet
    }

    func arrangeLastChild() {
        let lastChildren = children.suffix(2)
        guard lastChildren.count > 1
            else { return }
        let previousChild = lastChildren.first!
        let currentChild = lastChildren.last!

        let previousLinePositionInParent =
            containerNode.convertPosition(
                previousChild.lastLine.position,
                from: previousChild.containerNode
            )

        currentChild.containerNode.position.y =
            previousLinePositionInParent.y -
                previousChild.lastLine.lengthY / 2.0 -
                    currentChild.containerNode.lengthY / 2.0
    }
}
