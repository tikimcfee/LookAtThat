import Foundation
import SwiftSyntax

extension SwiftSyntaxParser {
    func __renderSheetTest(in sceneState: SceneState) {
        let fileUrl = Bundle.main.url(forResource: "WordNodeIntrospect", withExtension: "")
        prepareRendering(source: fileUrl!)
    }
}
