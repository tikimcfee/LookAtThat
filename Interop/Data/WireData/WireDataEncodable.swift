import Foundation
import SceneKit

struct WireCode: Codable {
    let sourceFile: String
}

extension SCNNode {
    var wireNode: WireNode { WireNode.from(self, isContainer: false) }
    var containerWireNode: WireNode { WireNode.from(self, isContainer: true) }
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

struct WireSheet: Codable, Identifiable {
    //    var parent: WireSheet?  : TODO: need to reset these at the end
    let id: String
    var containerNode: WireNode
    var backgroundGeometryNode: WireNode
    var backgroundGeometry: WireBox
    let allLines: [WireNode]
    let children: [WireSheet]
}

struct WireNode: Codable {
    let name: String?
    let children: [WireNode]
    let transform: WireMatrix4
    let pivot: WireMatrix4
    let eulers: WireVector3
    let box: WireBox?
    let text: WireText?
    let boundingMin: WireVector3
    let boundingMax: WireVector3
    let bitMask: Int

    public init(name: String?,
                children: [WireNode],
                transform: WireMatrix4,
                pivot: WireMatrix4,
                eulers: WireVector3,
                box: WireBox?,
                text: WireText?,
                boundingMin: WireVector3,
                boundingMax: WireVector3,
                bitMask: Int) {
        self.name = name
        self.children = children
        self.transform = transform
        self.pivot = pivot
        self.eulers = eulers
        self.box = box
        self.text = text
        self.boundingMin = boundingMin
        self.boundingMax = boundingMax
        self.bitMask = bitMask
    }

    /*
     If a WireNode is a container (isContainer = true), it means
     it should be created *without* recording all of its children.
     This is needed on the other end of reification, since the
     CodeSheet structure technically duplicates the scene hierarchy with its
     allLines[] and children[] construct. By ignoring these, we can use those
     constructs to accurately re-render the original sheet by iterating over
     allLines and children.containerNodes and adding them directly to
     containerNode directly, respectively.
     */
    public static func from(_ node: SCNNode,
                            isContainer: Bool = false) -> WireNode {
        WireNode(
            name: node.name,
            children: isContainer
                ? []
                : node.childNodes.map { WireNode.from($0) }
            ,
            transform: node.transform.wireMatrix,
            pivot: node.pivot.wireMatrix,
            eulers: node.eulerAngles.wireVector,
            box: (node.geometry as? SCNBox)?.wireBox,
            text: (node.geometry as? SCNText)?.wireText,
            boundingMin: node.boundingBox.min.wireVector,
            boundingMax: node.boundingBox.max.wireVector,
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
        node.eulerAngles = eulers.scnVector
        node.categoryBitMask = bitMask
        node.boundingBox = (boundingMin.scnVector, boundingMax.scnVector)
        return node
    }
}

struct WireColor: Codable, Equatable {
    var red, green, blue, alpha: CGFloat
    var make: NSUIColor {
        #if os(OSX)
        return NSUIColor(
            calibratedRed: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
        #elseif os(iOS)
        return NSUIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
        #endif
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
        text.font = FontRenderer.shared.renderingFont
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
    #if os(OSX)
    var rgba: (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        if let calibratedColor = usingColorSpace(.genericRGB) {
            var redComponent = CGFloat(0)
            var greenComponent = CGFloat(0)
            var blueComponent = CGFloat(0)
            var alphaComponent = CGFloat(0)
            calibratedColor.getRed(&redComponent,
                                   green: &greenComponent,
                                   blue: &blueComponent,
                                   alpha: &alphaComponent)
            return (redComponent, greenComponent, blueComponent, alphaComponent)
        }
        return nil
    }
    #elseif os(iOS)
    var rgba: (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        var redComponent = CGFloat(0)
        var greenComponent = CGFloat(0)
        var blueComponent = CGFloat(0)
        var alphaComponent = CGFloat(0)
        getRed(&redComponent,
               green: &greenComponent,
               blue: &blueComponent,
               alpha: &alphaComponent)
        return (redComponent, greenComponent, blueComponent, alphaComponent)
    }
    #endif

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
