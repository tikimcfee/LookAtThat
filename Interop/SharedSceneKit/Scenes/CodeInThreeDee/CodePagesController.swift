import Foundation
import SceneKit
import SwiftSyntax
import Combine
import FileKit

class CodePagesController: BaseSceneController, ObservableObject {

    var bumped = Set<Int>()
    var selectedSheets = Set<SyntaxIdentifier>()
    let highlightCache = HighlightCache()

    let wordNodeBuilder: WordNodeBuilder
    let codeGridParser: CodeGridParser
    let fileBrowser = FileBrowser()
    
    lazy var fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    lazy var fileEventStream = fileBrowser.$fileSeletionEvents.share().eraseToAnyPublisher()
    lazy var pathDepthStream = fileBrowser.$pathDepths.share().eraseToAnyPublisher()

    @Published var hoveredToken: String?
    @Published var hoveredInfo: CodeGridSemanticMap?

	lazy var hoverStream = $hoveredToken.share().eraseToAnyPublisher()
    lazy var hoverInfoStream = $hoveredInfo.share().eraseToAnyPublisher()
    
    var cancellables = Set<AnyCancellable>()
    
#if os(macOS)
    lazy var macosCompat = CodePagesControllerMacOSCompat(
        controller: self
    )
#endif

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.codeGridParser = CodeGridParser()
        super.init(sceneView: sceneView)
        
        codeGridParser.cameraNode = sceneView.pointOfView ?? sceneCameraNode
        codeGridParser.rootGeometryNode = sceneState.rootGeometryNode
    }
    
    func onNewFileStreamEvent(_ event: FileBrowser.Event) {
        switch event {
        case .noSelection:
            break
            
        case let .newSingleCommand(path, style):
            sceneTransaction {
                self.codeGridParser.withNewGrid(path.url) { plane, newGrid in
                    switch style {
                        
                    case .addToFocus:
                    #if os(macOS)
                        sceneTransaction(0) {
                            self.macosCompat.inputCompat.focus.layout { focus, box in
                                focus.addGridToFocus(newGrid, box.deepestDepth + 1)
                            }
                        }
                        self.macosCompat.inputCompat.focus.resize { focus, box in
                            box.rootNode.simdTranslate(dX: -newGrid.measures.lengthX / 2.0)
                        }
                        break
                    #else
                        break
                    #endif
                        
                    case .addToWorld:
                        self.addToRoot(rootGrid: newGrid)
                    }
                }
            }
            
        case let .newMultiCommandRecursiveAllLayout(parent, _):
            self.codeGridParser.__versionFour_RenderConcurrent(parent) { rootGrid in
                self.addToRoot(rootGrid: rootGrid)
            }
            
        case let .newMultiCommandRecursiveAllCache(parent):
            print("Start cache: \(parent.fileName)")
            self.codeGridParser.cacheConcurrent(parent) {
                print("Cache complete: \(parent.fileName)")
            }
        }
    }
    
    func addToRoot(rootGrid: CodeGrid) {
#if os(iOS)
        codeGridParser.editorWrapper.addInFrontOfCamera(grid: rootGrid)
#else
        sceneState.rootGeometryNode.addChildNode(rootGrid.rootNode)
#endif
    }
    
    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
#if os(OSX)
        DispatchQueue.main.async {
            self.macosCompat.attachMouseSink()
            self.macosCompat.attachKeyInputSink()
            self.macosCompat.attachEventSink()
            self.macosCompat.attachSearchInputSink()
        }
#endif
    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        // Clear out all the grids and things
        #if os(macOS)
        macosCompat.inputCompat.focus.resetState()
        macosCompat.inputCompat.focus.setNewFocus()
        #endif
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

extension CodePagesController {
    func selected(name: String) {
        bumpNodes (
            allTokensWith(name: name)
        )
    }
	
	func selected(id: SyntaxIdentifier, in source: CodeGridSemanticMap) {
        let isSelected = selectedSheets.toggle(id)
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
        return sceneState.rootGeometryNode.childNodes{ testNode, _ in
            return testNode.name == name
        }
    }

    func onTokensWith(type: String, _ operation: (SCNNode) -> Void) {
        sceneState.rootGeometryNode.enumerateChildNodes{ testNode, _ in
            if testNode.name?.contains(type) ?? false {
                operation(testNode)
            }
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
                let path: Path = Path(directory.parent.path)
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
