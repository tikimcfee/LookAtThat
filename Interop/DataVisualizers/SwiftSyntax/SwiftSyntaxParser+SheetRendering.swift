import Foundation
import SceneKit
import SwiftSyntax

private let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

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

        let directorySheet = CodeSheet()
            .backgroundColor(NSUIColor.black)
        directorySheet.containerNode.position.z = -300

        var lastChild: SCNNode? { directorySheet.containerNode.childNodes.last }
        var lastChildLengthX: VectorFloat { lastChild?.lengthX ?? 0.0 }
        var lastChildLengthY: VectorFloat { lastChild?.lengthY ?? 0.0 }

        var x = VectorFloat(0.0)
        var nextX: VectorFloat {
            x += lastChildLengthX + 16
            return x
        }

        var y = VectorFloat(0.0)
        var nextY: VectorFloat {
            y += 0
            return y
        }

        var z = VectorFloat(15.0)
        var nextZ: VectorFloat {
            z += 0
            return z
        }

        results.forEach { pair in
//            let lookAtCamera = SCNLookAtConstraint(target: sceneState.cameraNode)
//            lookAtCamera.localFront = SCNVector3Zero.translated(dZ: 1.0)
//            pair.1.containerNode.constraints = [lookAtCamera]

            pair.1.containerNode.position =
                SCNVector3Zero.translated(
                    dX: nextX + pair.1.halfLengthX,
//                    dY: -pair.1.halfLengthY - nextY,
                    dY: nextY - pair.1.halfLengthY,
                    dZ: nextZ
                )

            directorySheet.containerNode.addChildNode(pair.1.containerNode)
        }
        directorySheet.sizePageToContainerNode(pad: 20.0)

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(directorySheet.containerNode)
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

        let One_Radian = (180.0 / Float.pi) // 57.2958...°
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

        let rootCodeSheet = makeSheet(
            from: rootSyntaxNode!,
            semantics: SemanticInfo(
                syntaxId: rootSyntaxNode!.id,
                referenceName: preparedSourceFile!.lastPathComponent,
                syntaxTypeName: String(describing: rootSyntaxNode!.syntaxNodeType)
            )
        )
        .categoryMask(.rootCodeSheet)
        .sizePageToContainerNode()
        .sourceInfo(organizedInfo)
        .arrangeSemanticInfo(textNodeBuilder, asTitle: true)

        rootCodeSheet.containerNode.enumerateChildNodes { node, _ in
            guard node.name == kWhitespaceNodeName else { return }
            node.removeFromParentNode()
        }

        // Save node to be looked up later
        allRootContainerNodes[rootCodeSheet.containerNode] = rootCodeSheet

        return rootCodeSheet
    }

    func backgroundColor(for syntax: SyntaxChildren.Element) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }

    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.3, green: 0.2, blue: 0.3, alpha: 1.0)
        }
        if type == ClassDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        }
        if type == FunctionDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.5, alpha: 1.0)
        }
        if type == EnumDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.1, green: 0.3, blue: 0.4, alpha: 1.0)
        }
        if type == ExtensionDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.2, green: 0.4, blue: 0.4, alpha: 1.0)
        }
        if type == VariableDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        }
        if type == TypealiasDeclSyntax.self {
            return NSUIColor.init(deviceRed: 0.5, green: 0.3, blue: 0.5, alpha: 1.0)
        }
        return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    }
}

// CodeSheet operations
extension CodeSheet {
    func add(_ token: TokenSyntax,
             _ builder: WordNodeBuilder) {
        iterateTrivia(token.leadingTrivia, builder)
        let lines = token.splitText
        lines.forEach { line in
            arrange(line, builder)
            guard line != lines.last else { return }
            newlines(1)
        }
        iterateTrivia(token.trailingTrivia, builder)
    }

    @discardableResult
    func arrange(_ text: String,
                 _ builder: WordNodeBuilder) -> SCNNode {
        let newNode = builder.node(for: text)
        builder.arrange([newNode], on: lastLine)
        return newNode
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
                comment.substringLines
                    .map { $0.splitToWordsAndSpaces }
                    .forEach { lines in
                        lines.forEach {
                            arrange(String($0), builder)
                        }
                        newlines(1)
                    }
            case .spaces:
                let spaceNode = arrange(triviaPiece.stringify, builder)
                spaceNode.name = kWhitespaceNodeName
            default:
                arrange(triviaPiece.stringify, builder)
            }
        }
    }
}
