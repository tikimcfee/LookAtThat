import Foundation
import SceneKit

let kContainerName = "kContainerName"

// I want to find all the functions
// I want to find all the functions that take strings
// I want to find all the functions that take strings and return strings

struct IndexData: Hashable, Identifiable {
    var id: String { return parentSheetId }
    var parentSheetId: CodeSheet.ID

    var syntaxType: String
    var name: String

}

class CodeSheet: Identifiable, Equatable {
    lazy var id = UUID().uuidString
    lazy var containerNode: SCNNode = makeContainerNode()
    lazy var backgroundGeometryNode: SCNNode = SCNNode()
    lazy var backgroundGeometry: SCNBox = makePageGeometry()

    var children = [CodeSheet]()
    var allLines = [SCNNode]()
    var lastLine: SCNNode { allLines.last ?? { makeLineNode() }() }

    init(_ id: String? = nil) {
        self.id = id ?? self.id
    }

    public static func == (_ left: CodeSheet, _ right: CodeSheet) -> Bool {
        return left.id == right.id
            && left.allLines.elementsEqual(right.allLines)
            && left.children.elementsEqual(right.children)
    }
}

extension CodeSheet {
    func makeContainerNode() -> SCNNode {
        let container = SCNNode()
        container.name = kContainerName
        container.addChildNode(backgroundGeometryNode)
        backgroundGeometryNode.categoryBitMask = HitTestType.codeSheet
        backgroundGeometryNode.geometry = backgroundGeometry
        backgroundGeometryNode.name = id
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
        line.position = SCNVector3(Self.childPadding, -Self.childPadding, PAGE_EXTRUSION_DEPTH.vector)
        containerNode.addChildNode(line)
        allLines.append(line)
        return line
    }
}

extension CodeSheet {
    static let childPadding: VectorFloat = 0.5

    func newlines(_ count: Int) {
        for _ in 0..<count {
            setNewLine()
        }
    }

    private func setNewLine() {
        var (startPosition, height): (SCNVector3, VectorFloat)
        if let last = children.last  {
            startPosition = lastLinePosition(in: last)
            startPosition.x = Self.childPadding
            startPosition.z = lastLine.position.z
            height = last.lastLine.lengthY
        } else {
            startPosition = lastLine.position
            height = lastLine.lengthY
        }

        let newLine = makeLineNode()
        let newPosition = startPosition.translated(dY: -height)
        newLine.position = newPosition
    }

    func sizePageToContainerNode() {
        backgroundGeometry.width = containerNode.lengthX.cg + Self.childPadding.cg
        backgroundGeometry.height = containerNode.lengthY.cg - Self.childPadding.cg
        let centerY = -backgroundGeometry.height / 2.0
        let centerX = backgroundGeometry.width / 2.0
        backgroundGeometryNode.position.y = centerY.vector
        backgroundGeometryNode.position.x = centerX.vector
        containerNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
    }
 
    func appendChild(_ sheet: CodeSheet) {
        children.append(sheet)
        containerNode.addChildNode(sheet.containerNode)

        sheet.containerNode.position =
            SCNVector3Zero.translated(
                dX: sheet.halfLengthX + Self.childPadding,
                dZ: WORD_EXTRUSION_SIZE.vector
            )

        let myLastLinePosition = lastLinePosition(in: self)
        var sheetPosition = containerPosition(of: sheet)

        sheetPosition.y = myLastLinePosition.y
            - lastLine.lengthY
            - sheet.halfLengthY
//            - Self.childPadding

        sheet.containerNode.position = sheetPosition
        newlines(sheet.allLines.count)
    }
}

extension CodeSheet {

    var halfLengthY: VectorFloat { containerNode.lengthY / 2.0 }
    var halfLengthX: VectorFloat { containerNode.lengthX / 2.0 }

    private func set(_ position: SCNVector3, for child: CodeSheet) {
        set(position, for: child.containerNode)
    }

    private func set(_ position: SCNVector3, for node: SCNNode) {
        let final = containerNode.convertPosition(
            position,
            to: node
        )
        node.position = final
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
