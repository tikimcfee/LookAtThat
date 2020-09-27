import Foundation
import SceneKit

extension SCNNode {
    var wireNode: WireNode { WireNode.from(self) }
}
extension SCNText {
    var wireText: WireText { WireText.from(self) }
}
extension SCNBox {
    var wireBox: WireBox { WireBox.from(self) }
}
extension SCNMatrix4 {
    var wireMatrix: WireMatrix4 { WireMatrix4.from(self) }
}
extension SCNVector3 {
    var wireVector: WireVector3 { WireVector3.from(self) }
}
extension SCNGeometry {
    private var colorContents: NSUIColor? {
        firstMaterial?.diffuse.contents as? NSUIColor
    }
    var wireColor: WireColor? {
        return colorContents?.wireColor
    }
}

extension CodeSheet {
    var wireSheet: WireSheet {
        WireSheet.from(self)
    }
}

struct WireSheet: Codable {
    //    var parent: WireSheet?  : TODO: need to reset these at the end
    let id: String
    var containerNode: WireNode
    var pageGeometryNode: WireNode
    var pageGeometry: WireBox
    let allLines: [WireNode]
    let children: [WireSheet]

    static func from(_ sheet: CodeSheet) -> WireSheet {
        let newSheet = WireSheet(
            id: sheet.id,
            containerNode: sheet.containerNode.wireNode,
            pageGeometryNode: sheet.pageGeometryNode.wireNode,
            pageGeometry: sheet.pageGeometry.wireBox,
            allLines: sheet.allLines.map {
                WireNode.from($0)
            },
            children: sheet.children.map {
                WireSheet.from($0)
            }
        )
        return newSheet
    }

    func makeCodeSheet(_ parent: CodeSheet? = nil) -> CodeSheet {
        let root = CodeSheet(id)

        // xxx -- TODO, make this better! -- xxx
        /* Right now, the root node contains all the other nodes...
         which means when we serialize it, we serialize it, every code
         sheet, and every code sheet's child.
         That's not very efficient. It also causes problems.
         If we just draw all the children, we'll end up with duplicates
         of everything - nodes that aren't tracked by a code sheet (as
         reified from the WireNode) and the nodes that are (as reified from WireSheet).
         Options:
         - Make CodeSheet smart about parsing through a node hierarchy
         -- that sounds dangerous, especially since the allLines lines is meh..
         - Serialize more clever-er-ly
         -- I mention 'wirechild' and 'wireroot'. maybe CodeSheet can have a
         -- 'myNodes' set (or lookup by name) to separate the two
         - Completely change 'allLines' and 'containerNode'
         -- allLines is weird, especially since the node hierarchy is always there
         -- it's a structure around line breaks, which means we could tag those
         -- nodes as 'lineContainers'.
         -*** remove containers somewhere in the process
         -- below is a stopgap fix for rendering, although it definitely has bugs
         with respects to child code sheets. At the moment, this removes
         all containers from the root hierarchy which effectively leaves
         just the lines in tact. Even that's weird though, 'cause this whole
         thing is recursive and... ugh I'm confused.
        */
        root.containerNode = containerNode.scnNode
        root.containerNode.childNodes(passingTest: { node, stop in
            if node.parent == root.containerNode
                && node.name == kContainerName {
                return true
            }
            return false
        }).forEach{ $0.removeFromParentNode() }
        root.pageGeometryNode = pageGeometryNode.scnNode
        root.containerNode.addChildNode(root.pageGeometryNode)

        root.pageGeometry = pageGeometry.scnBox
        root.pageGeometryNode.categoryBitMask = HitTestType.codeSheet
        root.pageGeometryNode.geometry = root.pageGeometry
        root.pageGeometryNode.name = id

        for line in allLines {
            let line = line.scnNode
            root.allLines.append(line)
            root.containerNode.addChildNode(line)
        }
        for child in children {
            let sheet = child.makeCodeSheet(root)
            root.children.append(sheet)
            root.containerNode.addChildNode(sheet.containerNode)
            sheet.sizePageToContainerNode()
        }
        if root.allLines.count > 0 {
            root.lastLine = root.allLines.last!
        }
        root.sizePageToContainerNode()
        return root
    }
}

struct WireNode: Codable {
    let name: String?
    let children: [WireNode]
    let transform: WireMatrix4
    let pivot: WireMatrix4
    let box: WireBox?
    let text: WireText?
    let bitMask: Int

    enum Keys: CodingKey {
        case name
        case children
        case transform
        case pivot
        case box
        case text
        case bitMask
    }

    public init(name: String?,
                children: [WireNode],
                transform: WireMatrix4,
                pivot: WireMatrix4,
                box: WireBox?,
                text: WireText?,
                bitMask: Int) {
        self.name = name
        self.children = children
        self.transform = transform
        self.pivot = pivot
        self.box = box
        self.text = text
        self.bitMask = bitMask
    }

    public static func from(_ node: SCNNode) -> WireNode {
        WireNode(
            name: node.name,
            children: node.childNodes.map {
                WireNode.from($0)
            },
            transform: node.transform.wireMatrix,
            pivot: node.pivot.wireMatrix,
            box: (node.geometry as? SCNBox)?.wireBox,
            text: (node.geometry as? SCNText)?.wireText,
            bitMask: node.categoryBitMask
        )
    }

    var scnNode: SCNNode {
        let node = SCNNode()
        node.name = name
        children.forEach{ node.addChildNode($0.scnNode) }
        node.geometry = box?.scnBox ?? text?.scnText
        node.transform = transform.scnMatrix
        node.pivot = pivot.scnMatrix
        node.categoryBitMask = bitMask
        return node
    }

    // TODO: Should maybe have 'wire root' and 'wire child'..
    // TODO: or a better algorithm
    var scnNodeAsContainer: SCNNode {
        let node = SCNNode()
        node.name = name
        node.geometry = box?.scnBox ?? text?.scnText
        node.transform = transform.scnMatrix
        node.pivot = pivot.scnMatrix
        node.categoryBitMask = bitMask
        return node
    }
}

struct WireColor: Codable, Equatable {
    var red, green, blue, alpha: CGFloat
    var make: NSUIColor {
        return NSUIColor(
            calibratedRed: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

struct WireBox: Codable, Equatable {
    let length, width, height: CGFloat
    let chamfer: CGFloat
    let color: WireColor?

    static func from(_ box: SCNBox) -> WireBox {
        return WireBox(
            length: box.length,
            width: box.width,
            height: box.height,
            chamfer: box.height,
            color: box.wireColor
        )
    }

    var scnBox: SCNBox {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: chamfer)
        box.firstMaterial?.diffuse.contents = color?.make
        return box
    }
}

struct WireText: Codable, Equatable {
    let string: String
    let extrusion: CGFloat
    let color: WireColor?

    static func from(_ text: SCNText) -> WireText {
        return WireText(
            string: text.string as! String,
            extrusion: text.extrusionDepth,
            color: text.wireColor
        )
    }

    var scnText: SCNText {
        let text = SCNText(string: string, extrusionDepth: extrusion)
        text.font = kDefaultSCNTextFont
        text.firstMaterial?.diffuse.contents = color?.make
        return text
    }
}

struct WireVector3: Codable, Equatable {
    let x, y, z: VectorFloat
    static func from(_ vector: SCNVector3) -> WireVector3 {
        WireVector3(
            x: vector.x,
            y: vector.y,
            z: vector.z
        )
    }
    var scnVector: SCNVector3 {
        SCNVector3(x: x, y: y, z: z)
    }
}

struct WireMatrix4: Codable, Equatable {
    let m11, m12, m13, m14: VectorFloat
    let m21, m22, m23, m24: VectorFloat
    let m31, m32, m33, m34: VectorFloat
    let m41, m42, m43, m44: VectorFloat
    static func from(_ matrix: SCNMatrix4) -> WireMatrix4 {
        WireMatrix4(
            m11: matrix.m11, m12: matrix.m12, m13: matrix.m13, m14: matrix.m14,
            m21: matrix.m21, m22: matrix.m22, m23: matrix.m23, m24: matrix.m24,
            m31: matrix.m31, m32: matrix.m32, m33: matrix.m33, m34: matrix.m34,
            m41: matrix.m41, m42: matrix.m42, m43: matrix.m43, m44: matrix.m44
        )
    }
    var scnMatrix: SCNMatrix4 {
        SCNMatrix4(
            m11: m11, m12: m12, m13: m13, m14: m14,
            m21: m21, m22: m22, m23: m23, m24: m24,
            m31: m31, m32: m32, m33: m33, m34: m34,
            m41: m41, m42: m42, m43: m43, m44: m44
        )
    }
}

/**
 A tuple of the red, green, blue and alpha components of this NSColor calibrated
 in the RGB color space. Each tuple value is a CGFloat between 0 and 1.
 https://github.com/jeffreymorganio/nscolor-components/blob/master/Sources/NSColor%2BComponents.swift
 https://stackoverflow.com/questions/15682923/convert-nscolor-to-rgb/15682981#15682981
 */
extension NSUIColor {
    var rgba: (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        if let calibratedColor = usingColorSpace(.genericRGB) {
            var redComponent = CGFloat(0)
            var greenComponent = CGFloat(0)
            var blueComponent = CGFloat(0)
            var alphaComponent = CGFloat(0)
            calibratedColor.getRed(&redComponent,
                                   green: &greenComponent,
                                   blue: &blueComponent,
                                   alpha: &alphaComponent
            )
            return (redComponent, greenComponent, blueComponent, alphaComponent)
        }
        return nil
    }

    var wireColor: WireColor {
        let rgba = self.rgba!
        return WireColor(
            red: rgba.red,
            green: rgba.green,
            blue: rgba.blue,
            alpha: rgba.alpha
        )
    }
}
