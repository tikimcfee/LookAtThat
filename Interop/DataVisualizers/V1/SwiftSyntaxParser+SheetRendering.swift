import Foundation
import SceneKit
import SwiftSyntax

let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

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

        var x = VectorFloat(-16.0)
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
            let radius: CGFloat = node.lengthX.cg / 2.0
            let angleStep: Float = 2.0 * Float.pi / Float(nodes.count)

            let xPos = focalX + cosf(angleStep * count).cg * radius
            let zPos = focalZ + sinf(angleStep * count).cg * radius
            node.position = SCNVector3(xPos, 0, zPos)

            if count.truncatingRemainder(dividingBy: 2.0) == 0 {
                node.eulerAngles.y = ninetyInRadians.vector
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

extension SwiftSyntaxParser: SwiftSyntaxFileLoadable {
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
}

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
        .removingWhitespace()
//        .arrangeSemanticInfo(textNodeBuilder, asTitle: true)

        // Save node to be looked up later
        allRootContainerNodes[rootCodeSheet.containerNode] = rootCodeSheet

        return rootCodeSheet
    }

    func backgroundColor(for syntax: SyntaxChildren.Element) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }

    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self {
            return color(0.3, 0.2, 0.3, 1.0)
        }
        if type == ClassDeclSyntax.self {
            return color(0.2, 0.2, 0.4, 1.0)
        }
        if type == FunctionDeclSyntax.self {
            return color(0.2, 0.2, 0.5, 1.0)
        }
        if type == EnumDeclSyntax.self {
            return color(0.1, 0.3, 0.4, 1.0)
        }
        if type == ExtensionDeclSyntax.self {
            return color(0.2, 0.4, 0.4, 1.0)
        }
        if type == VariableDeclSyntax.self {
            return color(0.3, 0.3, 0.3, 1.0)
        }
        if type == TypealiasDeclSyntax.self {
            return color(0.5, 0.3, 0.5, 1.0)
        }
        else {
            return color(0.2, 0.2, 0.2, 1.0)
        }
    }

    private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat)  -> NSUIColor {
        return NSUIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension SwiftSyntaxParser: SwiftSyntaxCodeSheetBuildable { }

protocol SwiftSyntaxCodeSheetBuildable {
    var organizedInfo: OrganizedSourceInfo { get set }
    var textNodeBuilder: WordNodeBuilder { get }
    func makeSheet(from node: SyntaxProtocol, semantics: SemanticInfo?) -> CodeSheet
}

extension SwiftSyntaxCodeSheetBuildable {
    
    func makeSheet(from node: SyntaxProtocol,
                   semantics: SemanticInfo? = nil) -> CodeSheet {
        let newSheet = CodeSheet()
            .semantics(semantics)
        
        for nodeChildSyntax in node.children {
            if let existingSheet = self[nodeChildSyntax.id] {
                if let declBlock = nodeChildSyntax.as(MemberDeclBlockSyntax.self) {
                    addMemberDeclBlock(declBlock, to: newSheet)
                }
                else if let codeBlock = nodeChildSyntax.as(CodeBlockSyntax.self) {
                    addCodeBlock(codeBlock, to: newSheet)
                }
                else if let clodeBlockItemList = nodeChildSyntax.as(CodeBlockItemListSyntax.self) {
                    addCodeBlockItemList(clodeBlockItemList, to: newSheet)
                }
//                else if let functionCall = nodeChildSyntax.as(FunctionCallExprSyntax.self) {
//                    addFuncCall(functionCall, to: newSheet)
//                }
                else if let memberList = nodeChildSyntax.as(MemberDeclListSyntax.self) {
                    addMemberList(memberList, to: newSheet)
                }
                else if let ifConfigList = nodeChildSyntax.as(IfConfigClauseListSyntax.self) {
                    addPoundList(ifConfigList, to: newSheet)
                }
                else if let poundIf = nodeChildSyntax.as(IfConfigDeclSyntax.self) {
                    addPoundIf(poundIf, to: newSheet)
                }
                else {
                    newSheet.appendChild(existingSheet)
                }
            } else {
                for token in nodeChildSyntax.tokens {
                    newSheet.add(token, textNodeBuilder)
                }
            }
        }

        newSheet.sizePageToContainerNode()
        return newSheet
    }

    func addMemberList(_ list: MemberDeclListSyntax, to parent: CodeSheet) {
        for child in list.children {
            if let sheet = self[child.id] {
                parent.appendChild(sheet)
            }
        }
    }

    func addPoundList(_ poundList: IfConfigClauseListSyntax, to parent: CodeSheet) {
        for child in poundList.children {
            if let sheet = self[child.id] {
                parent.appendChild(sheet)
            }
        }
    }

    func addPoundIf(_ pound: IfConfigDeclSyntax, to parent: CodeSheet) {
        for clause in pound.clauses {
            parent.add(clause.poundKeyword, textNodeBuilder)
            if let condition = clause.condition {
                for token in condition.tokens {
                    parent.add(token, textNodeBuilder)
                }
            }
            for child in clause.elements.children {
                if let sheet = self[child.id] {
                    parent.appendChild(sheet)
                }
            }
        }
        parent.add(pound.poundEndif, textNodeBuilder)
    }

    func addFuncCall(_ call: FunctionCallExprSyntax, to parent: CodeSheet) {
        for child in call.children {
            if let childSheet = self[child.id] {
                parent.appendChild(childSheet)
            }
        }
    }

    func addMemberDeclBlock(_ block: MemberDeclBlockSyntax, to parent: CodeSheet) {
        parent.add(block.leftBrace, textNodeBuilder)
        for listItem in block.members {
            if let childSheet = self[listItem.decl.id] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(block.rightBrace, textNodeBuilder)
    }

    func addCodeBlock(_ block: CodeBlockSyntax, to parent: CodeSheet) {
        parent.add(block.leftBrace, textNodeBuilder)
        for statement in block.statements {
            if let childSheet = self[statement.id] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(block.rightBrace, textNodeBuilder)
    }

    func addCodeBlockItemList(_ list: CodeBlockItemListSyntax, to parent: CodeSheet) {
        for blockItemChild in list {
            if let childSheet = self[blockItemChild.id] {
                parent.appendChild(childSheet)
            }
        }
    }

    internal subscript(_ index: SyntaxIdentifier) -> CodeSheet? {
        return organizedInfo.allSheets[index]
    }
}
