import Foundation
import SceneKit

let kContainerName = "kContainerName"
class CodeSheet: Identifiable, Equatable {
    var id = UUID().uuidString
    var allLines = [SCNNode]()
    var iteratorY = WordPositionIterator()
    var children = [CodeSheet]()

    lazy var containerNode: SCNNode = makeContainerNode()
    lazy var pageGeometryNode: SCNNode = SCNNode()
    lazy var pageGeometry: SCNBox = makePageGeometry()
    var lastLine: SCNNode {
        return allLines.last ?? {
            return makeLineNode()
        }()
    }

    init(_ id: String? = nil) {
        self.id = id ?? self.id
    }

    public static func == (_ left: CodeSheet, _ right: CodeSheet) -> Bool {
        return left.id == right.id
            && left.allLines.elementsEqual(right.allLines)
            && left.children.elementsEqual(right.children)
//            && left.parent?.id == right.parent?.id
    }
}

extension CodeSheet {
    func makeContainerNode() -> SCNNode {
        let container = SCNNode()
        container.name = kContainerName
        container.addChildNode(pageGeometryNode)
        pageGeometryNode.categoryBitMask = HitTestType.codeSheet
        pageGeometryNode.geometry = pageGeometry
        pageGeometryNode.name = id
        return container
    }

    func makePageGeometry() -> SCNBox {
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }

    func makeLineNode() -> SCNNode {
        let line = SCNNode()
        line.position = SCNVector3(0, 0, PAGE_EXTRUSION_DEPTH)
        containerNode.addChildNode(line)
        allLines.append(line)
        return line
    }
}

extension CodeSheet {
    func newlines(_ count: Int) {
        for _ in 0..<count {
            setNewLine()
        }
    }

    private func setNewLine() {
        let positioningLine = children.last?.lastLine ?? lastLine
        let newLine = makeLineNode()
        newLine.position =
            positioningLine.position.translated(dY: -positioningLine.lengthY)
    }

    func sizePageToContainerNode() {
        pageGeometry.width = containerNode.lengthX.cg
        pageGeometry.height = containerNode.lengthY.cg
        let centerY = -pageGeometry.height / 2.0
        let centerX = pageGeometry.width / 2.0
        pageGeometryNode.position.y = centerY.vector
        pageGeometryNode.position.x = centerX.vector
        containerNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0);
    }

    func spawnChild() -> CodeSheet {
        let codeSheet = CodeSheet()
        containerNode.addChildNode(codeSheet.containerNode)
        children.append(codeSheet)
        return codeSheet
    }

    func layoutChildren() {
        for (index, firstChild) in children.enumerated() {
            guard index != children.endIndex - 1 else { return }
            let nextChild = children[index + 1]

            let firstChildLastLine = lastLinePosition(in: firstChild)
            var nextChildContainerPosition = containerPosition(of: nextChild)

            nextChildContainerPosition.y = firstChildLastLine.y
                - firstChild.lastLine.lengthY
                - nextChild.containerNode.lengthY / 2.0
                - 2

            set(nextChildContainerPosition, for: nextChild)
        }
    }

    private func set(_ position: SCNVector3, for child: CodeSheet) {
        let final = containerNode.convertPosition(
            position,
            to: child.containerNode
        )
        child.containerNode.position = final
    }

    private func lastLinePosition(in sheet: CodeSheet) -> SCNVector3 {
        return containerNode.convertPosition(
            sheet.lastLine.position,
            from: sheet.containerNode
        )
    }

    private func containerPosition(of sheet: CodeSheet) -> SCNVector3 {
        return containerNode.convertPosition(
            sheet.containerNode.position,
            from: sheet.containerNode
        )
    }
}
