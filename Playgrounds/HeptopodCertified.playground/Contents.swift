//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

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




// Present the view in Playground
PlaygroundPage.current.liveView = root

