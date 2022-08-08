//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport
import SceneKit

let delegate = AppDelegate()
let root = delegate.makeRootContentView()
root.frame.size = CGSize(width: 500, height: 500)

let controller = CodePagesController.shared
let scene = controller.sceneState

let glyphs = controller.codeGridParser.glyphCache

func key(_ text: String) -> GlyphCacheKey {
    GlyphCacheKey(text, .blue, .red)
}

let sentences = [
    "Hello, my name is Ivan.",
    "I am looking for something.",
    "Can you help me?"
]

func nodesForSentence(_ sentence: String) -> [GlyphNode] {
    sentence.split(separator: " ")
        .map { glyphs[key(String($0))] }
        .map { GlyphNode.make($0.0, $0.1, $0.2) }
}

let nodes = nodesForSentence(sentences[0])
    
var step = 0.0
func incrementStep(_ node: GlyphNode) {
    step = node.boundsInWorld.max.x + 0.67
}

let bridge = MetalLinkNodeBridge()


for node in nodes {
    bridge.attachedDefaultSceneProgram(node)
    
    
//    let image = UIImage(named: "diffuse")!
//    let imageProperty = SCNMaterialProperty(contents: image)
//    // The name you supply here should match the texture parameter name in the fragment shader
//    material.setValue(imageProperty, forKey: "diffuseTexture")
    
    scene.rootGeometryNode.addChildNode(node)
    node.position.x = step + node.boundsWidth / 2.0
    incrementStep(node)
}

// Present the view in Playground
PlaygroundPage.current.liveView = root
