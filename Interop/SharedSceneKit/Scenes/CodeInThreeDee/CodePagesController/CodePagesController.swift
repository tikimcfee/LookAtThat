import Foundation
import SceneKit
import SwiftSyntax
import Combine
import FileKit

class CodePagesController: BaseSceneController, ObservableObject {

    var bumped = Set<Int>()
    var selectedIdentifiers = Set<SyntaxIdentifier>()
    let highlightCache = HighlightCache()
    
    typealias Focus = [(SemanticInfo, SortedNodeSet)]
    var currentFocus: Focus? // todo: use sets to have multiple threads focused on different nodes
    var currentFocusGrid: CodeGrid? // todo: use sets to have multiple threads focused on different nodes

    let wordNodeBuilder: WordNodeBuilder
    let codeGridParser: CodeGridParser
    let fileBrowser = FileBrowser()
    
    lazy var fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    lazy var fileEventStream = fileBrowser.$fileSeletionEvents.share().eraseToAnyPublisher()

    @Published var hoveredToken: String = ""
    @Published var hoveredInfo: CodeGridSemanticMap?
    @Published var hoveredGrid: CodeGrid?
    lazy var pointerNode: SCNNode = makePointerNode()

	lazy var hoverStream = $hoveredToken.share().eraseToAnyPublisher()
    lazy var hoverInfoStream = $hoveredInfo.share().eraseToAnyPublisher()
    lazy var hoverGridStream = $hoveredGrid.share().eraseToAnyPublisher()
    
    var cancellables = Set<AnyCancellable>()

#if os(macOS)
    lazy var compat = CodePagesControllerMacOSCompat(
        controller: self
    )
    var commandHandler: CommandHandler { compat }
#elseif os(iOS)
    lazy var compat = ControlleriOSCompat(
        controller: self
    )
    var commandHandler: CommandHandler { compat }
#endif

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.codeGridParser = CodeGridParser()
        super.init(sceneView: sceneView)
        
        if let pointOfView = sceneView.pointOfView {
            print("CodePagesController using point of view for camera node")
            codeGridParser.cameraNode = pointOfView
        } else {
            codeGridParser.cameraNode = sceneCameraNode
        }
        codeGridParser.rootGeometryNode = sceneState.rootGeometryNode
    }
    
    func onNewFileStreamEvent(_ event: FileBrowser.Event) {
        switch event {
        case .noSelection:
            break
            
        case let .newSingleCommand(path, style):
            commandHandler.handleSingleCommand(path, style)
            
        case let .newMultiCommandRecursiveAllLayout(parent, _):
            codeGridParser.__versionThree_RenderConcurrent(parent) { rootGrid in
//            codeGridParser.__versionFour_RenderConcurrent(parent) { rootGrid in
                self.addToRoot(rootGrid: rootGrid)
            }
            
        case let .newMultiCommandRecursiveAllCache(parent):
            print("Start cache: \(parent.fileName)")
            codeGridParser.cacheConcurrent(parent) {
                print("Cache complete: \(parent.fileName)")
            }
        }
    }
    
    func addToRoot(rootGrid: CodeGrid) {
#if os(iOS)
        codeGridParser.editorWrapper.addInFrontOfCamera(grid: rootGrid)
#else
        sceneState.rootGeometryNode.addChildNode(rootGrid.rootNode)
        rootGrid.translated(
            dX: -rootGrid.measures.lengthX / 2.0,
            dY: rootGrid.measures.lengthY / 2.0,
            dZ: -2000
        )
#endif
    }
    
    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
#if os(OSX)
        DispatchQueue.main.async {
            self.compat.attachMouseSink()
            self.compat.attachKeyInputSink()
            self.compat.attachEventSink()
            self.compat.attachSearchInputSink()
        }
#elseif os(iOS)
        DispatchQueue.main.async {
            self.compat.attachEventSink()
            self.compat.attachSearchInputSink()
        }
#endif

    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        // Clear out all the grids and things
        compat.inputCompat.focus.resetState()
        compat.inputCompat.focus.setNewFocus()
    }
}

extension Set where Element == SyntaxIdentifier {
    mutating func toggle(_ id: SyntaxIdentifier) -> Bool {
        if contains(id) {
            remove(id)
            return false
        } else {
            insert(id)
            return true
        }
    }
}

//MARK: - Path tracing

extension CodePagesController {
    func setNewFocus(id: SyntaxIdentifier, in grid: CodeGrid) {
        var didSwap = false
        if let lastFocus = currentFocus,
           let lastFocusGrid = currentFocusGrid
        {
            swapFocusHighlight(lastFocus)
            if lastFocusGrid != grid {
                lastFocusGrid.swapOutRootGlyphs()
//                lastFocusGrid.rawGlyphsNode.translate(dZ: -25)
                didSwap = true
            }
        }
        let focus = (try? grid.codeGridSemanticInfo.collectAssociatedNodes(id, grid.tokenCache)) ?? []
        currentFocus = focus
        currentFocusGrid = grid
        swapFocusHighlight(focus)
        if didSwap {
            grid.swapInRootGlyphs()
//            grid.rawGlyphsNode.translate(dZ: 25)
        }
    }
    
    private func swapFocusHighlight(_ focus: Focus) {
        for (_, nodeSet) in focus {
            for node in nodeSet {
                // swap between the geometries instead of another cache
                if let highlightCache = codeGridParser.glyphCache[node],
                   let lastGeometry = node.geometry
                {
                    node.geometry = highlightCache.0
                    codeGridParser.glyphCache[node] = (lastGeometry, highlightCache.1)
                }
            }
        }
    }
    
    func zoom(id: SyntaxIdentifier, in grid: CodeGrid) {
        sceneTransaction {
            sceneState.cameraNode.worldPosition = grid.rootNode.worldPosition.translated(dZ: 150)
        }
    }
    
    func makePointerNode() -> SCNNode {
        let node = SCNNode()
        node.name = "ExecutionPointer"
        node.geometry = SCNSphere(radius: 4.0)
        node.geometry?.materials.first?.diffuse.contents = NSUIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        return node
    }
    
    func moveExecutionPointer(id: SyntaxIdentifier, in grid: CodeGrid) {
        sceneTransaction {
            if pointerNode.parent == nil {
                sceneState.rootGeometryNode.addChildNode(pointerNode)
            }
            
            let allCollectedNodes = try? grid.codeGridSemanticInfo.collectAssociatedNodes(id, grid.tokenCache)
            
            if let firstNodeSet = allCollectedNodes?.first,
               let firstNode = firstNodeSet.1.first {
                
                pointerNode.worldPosition = grid.rootNode.worldPosition.translated(
                    dX: firstNode.position.x,
                    dY: firstNode.position.y,
                    dZ: firstNode.position.z
                )
                
                sceneState.cameraNode.worldPosition = SCNVector3(
                    x: pointerNode.worldPosition.x,
                    y: pointerNode.worldPosition.y,
                    z: sceneState.cameraNode.worldPosition.z
                )
                
                sceneState.cameraNode.look(
                    at: pointerNode.worldPosition,
                    up: sceneState.rootGeometryNode.worldUp,
                    localFront: SCNNode.localFront
                )
            }
        }
    }
}

extension CodePagesController {
    func selected(name: String) {
        bumpNodes(allTokensWith(name: name))
    }
	
	func selected(id: SyntaxIdentifier, in source: CodeGridSemanticMap) {
        let isSelected = selectedIdentifiers.toggle(id)
        sceneTransaction {
            try? source.forAllNodesAssociatedWith(id, codeGridParser.tokenCache) { info, nodes in
                nodes.forEach { node in
                    node.position = node.position.translated(
                        dZ: isSelected ? 25 : -25
                    )
                }
            }
        }
	}

    func toggleNodeHighlight(_ node: SCNNode) {
        for letter in node.childNodes {
            letter.geometry = highlightCache[letter.geometry!]
        }
    }

    func bumpNodes(_ nodes: [SCNNode]) {
        sceneTransaction {
            for node in nodes {
                let hash = node.hash
                if bumped.contains(hash) {
                    bumped.remove(hash)
                    node.position = node.position.translated(dZ: -50)
                    toggleNodeHighlight(node)
                } else {
                    bumped.insert(hash)
                    node.position = node.position.translated(dZ: 50)
                    toggleNodeHighlight(node)
                }
            }
        }
    }

    func allTokensWith(name: String) -> [SCNNode] {
        return sceneState.rootGeometryNode.childNodes { testNode, _ in
            return testNode.name == name
        }
    }
	
	func renderSyntax(_ handler: @escaping (CodeGridSemanticMap) -> Void) {
        requestSourceFile { fileUrl in
            self.workerQueue.async {
                guard let newSyntaxGlyphGrid = self.codeGridParser.renderGrid(fileUrl) else { return }
				
				// this is generally a UI component looking for the current requested syntax glyphs
				// they're getting the result new file, and it's assumed the total state of the global
				// underlying parser and controller are known.
				handler(newSyntaxGlyphGrid.codeGridSemanticInfo)
				
				// the grid is assumed to be as 0,0,0 at its root inititally. sorry, just makes life easier from here.
				// past this transaction, you do what ya like.
				
				// this lets us do cool tricks like be in 'editor mode'
				// editor mode assumes that your current perspective is your preferred one, and calling the single
				// renderSyntax function will apply some layout goodies to add the result root glyph, and make it look really cool. 
				// when this mode is off, it will do some necessarily sane thing like defaulting to a value that produces
				// the least known human harm when implemented.
                sceneTransaction {
                    self.codeGridParser.editorWrapper.addGrid(style: .trailingFromLastGrid(newSyntaxGlyphGrid))
                }
            }
        }
    }
}

// MARK: File loading

extension CodePagesController {
    func requestSetRootDirectory() {
        #if os(OSX)
        selectDirectory { result in
            switch result {
            case .failure(let error):
                print(error)
                
            case .success(let directory):
                let path: FileKitPath = Path(directory.parent.path)
                self.fileBrowser.setRootScope(path)
            }
        }
        #endif
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
