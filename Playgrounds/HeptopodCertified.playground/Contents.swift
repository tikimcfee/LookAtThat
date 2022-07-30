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

func pointOnCircle(angle: Int, radius: Int) {
    
}


func nodesForSentence(_ sentence) -> [GlyphNode] {
    sentence.split(separator: " ")
        .map { glyphs[key(String($0))] }
        .map { GlyphNode.make($0.0, $0.1, $0.2) }
}

let nodes = sentences.redu
    

var step = 10.0
for node in nodes {
    node.position.x += step
    step += 10.0
    scene.rootGeometryNode.addChildNode(node)
}

// Present the view in Playground
PlaygroundPage.current.liveView = root

