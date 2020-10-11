import Foundation
import SceneKit
import SwiftSyntax

#if os(OSX)
// Node building
extension SwiftSyntaxParser {

    func prepareRendering(source fileUrl: URL) {
        organizedInfo = OrganizedSourceInfo()
        preparedSourceFile = fileUrl
        guard let loadedFile = loadSourceUrl(fileUrl) else {
            print("Couldn't load \(fileUrl)")
            return
        }
        sourceFileSyntax = loadedFile
        rootSyntaxNode = visit(loadedFile)
    }

    func render(in sceneState: SceneState) -> OrganizedSourceInfo {
        guard rootSyntaxNode != nil else {
            print("No syntax to render for \(String(describing: preparedSourceFile))")
            return organizedInfo
        }
        let rootSheet = makeSheetFromInfo()
        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(rootSheet.containerNode)
        }
        return organizedInfo
    }

    func renderDirectory(_ directory: Directory, in sceneState: SceneState) -> [OrganizedSourceInfo] {
        var results = [(OrganizedSourceInfo, CodeSheet)]()
        for url in directory.swiftUrls {
            prepareRendering(source: url)
            results.append((organizedInfo, makeSheetFromInfo()))
        }
        let groupNode = SCNNode()
        results.forEach { pair in
            groupNode.addChildNode(pair.1.containerNode)
//            let lookAtCamera = SCNLookAtConstraint(target: sceneState.cameraNode)
//            lookAtCamera.localFront = SCNVector3Zero.translated(dZ: 1.0)
//            pair.1.containerNode.constraints = [lookAtCamera]

            pair.1.containerNode.position.x = 0
            pair.1.containerNode.position.y = 0
            pair.1.containerNode.position =
                pair.1.containerNode.position.translated(
//                    dX: pair.1.halfLengthX,
//                    dY: -pair.1.halfLengthY,
                    dZ: -40
                )
            groupNode.eulerAngles.y += 0.5
        }

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(groupNode)
        }

        return results.map{ $0.0 }
    }

    func arrangeNodesWeirdly(nodes:[SCNNode]) {
//        arrangeNodesWeirdly(
//            nodes: results.map{
//                groupNode.addChildNode($0.1.containerNode)
//                return $0.1.containerNode
//            }
//        )
        let focalX: CGFloat = 0.0
        let focalZ: CGFloat = 0.0

        var count: Float = 0

        var One_Radian = (180.0 / Float.pi) // 57.2958...°
        let ninetyInRadians = 90.0 / One_Radian

        for node in nodes {
            let radius: CGFloat = node.lengthX / 2.0
            let angleStep: Float = 2.0 * Float.pi / Float(nodes.count)

            let xPos = focalX + cosf(angleStep * count).cg * radius
            let zPos = focalZ + sinf(angleStep * count).cg * radius
            node.position = SCNVector3(xPos, 0, zPos)

            if count.truncatingRemainder(dividingBy: 2.0) == 0 {
                node.eulerAngles.y = ninetyInRadians.cg
            }

            count = count + 1.0
        }
    }

    func renderAndDuplicate(in sceneState: SceneState) {
        guard rootSyntaxNode != nil else {
            print("No syntax to render for \(String(describing: preparedSourceFile))")
            return
        }

        sceneTransaction {
            let parentCodeSheet = makeSheetFromInfo()
            let wireSheet = parentCodeSheet.wireSheet
            let backConverted = wireSheet.makeCodeSheet()
            backConverted.containerNode.position.x += 100

            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
            sceneState.rootGeometryNode.addChildNode(backConverted.containerNode)
        }
    }
}

// File loading
extension SwiftSyntaxParser {
    func requestSourceDirectory(_ receiver: @escaping (Directory) -> Void) {
        openDirectory { directoryResult in
            switch directoryResult {
            case let .success(directory):
                receiver(directory)
            case let .failure(error):
                print(error)
            }
        }
    }

    func requestSourceFile(_ receiver: @escaping (URL) -> Void) {
        openFile { fileReslt in
            switch fileReslt {
            case let .success(url):
                receiver(url)
            case let .failure(error):
                print(error)
            }
        }
    }

    func parse(_ source: String) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(source: source)
        } catch {
            print("|InvalidRawSource| failed to load > \(error)")
            return nil
        }
    }

    private func loadSourceUrl(_ url: URL) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(url)
        } catch {
            print("|\(url)| failed to load > \(error)")
            return nil
        }
    }
}
#endif

extension SwiftSyntaxParser {

    func makeSheetFromInfo() -> CodeSheet {

        let parentCodeSheet = makeSheet(
            from: rootSyntaxNode!,
            semantics: SemanticInfo(
                syntaxId: rootSyntaxNode!.id,
                referenceName: preparedSourceFile!.lastPathComponent,
                syntaxTypeName: String(describing: rootSyntaxNode!.syntaxNodeType)
            )
        )

        parentCodeSheet.sizePageToContainerNode()
        if let semanticSheet = parentCodeSheet.arrangeSemanticInfo(textNodeBuilder) {
            semanticSheet.containerNode.position =
                semanticSheet.containerNode.position.translated(
                    dX: semanticSheet.containerNode.lengthX,
                    dY: semanticSheet.containerNode.lengthY
                )
        }

        parentCodeSheet.containerNode.position =
            parentCodeSheet.containerNode.position
                .translated(dZ: nextZ - 50)

        // Save node to be looked up later
        nodesToSheets[parentCodeSheet.containerNode] = parentCodeSheet

        return parentCodeSheet
    }

    func backgroundColor(for syntax: SyntaxChildren.Element) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }

    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self { return NSUIColor.systemTeal }
        if type == ClassDeclSyntax.self { return NSUIColor.systemIndigo }
        if type == FunctionDeclSyntax.self { return NSUIColor.systemPink }
        if type == EnumDeclSyntax.self { return NSUIColor.systemOrange }
        if type == ExtensionDeclSyntax.self { return NSUIColor.systemBrown }
        if type == VariableDeclSyntax.self { return NSUIColor.systemGreen }
        if type == TypealiasDeclSyntax.self { return NSUIColor.systemPurple }
        return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
    }
}

// CodeSheet operations
extension CodeSheet {
    func add(_ token: TokenSyntax,
             _ builder: WordNodeBuilder) {
        iterateTrivia(token.leadingTrivia, builder)
        arrange(token.text, builder)
        iterateTrivia(token.trailingTrivia, builder)
    }

    func arrange(_ text: String,
                 _ builder: WordNodeBuilder) {
        let newNode = builder.node(for: text)
        [newNode].arrangeInLine(on: lastLine)
    }

    func iterateTrivia(_ trivia: Trivia,
                       _ builder: WordNodeBuilder) {
        for triviaPiece in trivia {
            switch triviaPiece {
            case let .newlines(count):
                newlines(count)
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                let lines = comment.split(whereSeparator: { $0.isNewline })
                for piece in lines {
                    arrange(String(piece), builder)
                    if piece != lines.last {
                        newlines(1)
                    }
                }
            default:
                arrange(triviaPiece.stringify, builder)
            }
        }
    }
}
