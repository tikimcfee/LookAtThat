import Foundation
import SceneKit
import SwiftSyntax
import Combine

var z = VectorFloat(0)
var nextZ: VectorFloat {
    z -= 15
    return z
}

class CodePagesController: BaseSceneController, ObservableObject {

    let iteratorY = WordPositionIterator()
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
	lazy var hoverStream = $hoveredToken.share().eraseToAnyPublisher()
    
    var cancellables = Set<AnyCancellable>()

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.codeGridParser = CodeGridParser()
        super.init(sceneView: sceneView)
        
        // Don't add the world immediately; use it to draw grids and then add the grids instead
//        sceneState.rootGeometryNode.addChildNode(
//            codeGridParser.world.rootContainerNode
//        )
        codeGridParser.cameraNode = sceneView.pointOfView ?? sceneCameraNode
    }
    
    #if os(macOS)
    lazy var keyboardInterceptor: KeyboardInterceptor = {
        let interceptor = KeyboardInterceptor(
            targetCamera: sceneCamera,
            targetCameraNode: sceneCameraNode
        )
        interceptor.onNewFileOperation = { op in
            switch op {
            case .openDirectory:
                self.requestSetRootDirectory()
                break
            }
        }
        interceptor.onNewFocusChange = { focus in
            sceneTransaction {
                self.codeGridParser.editorWrapper.changeFocus(focus)
            }
        }
        return interceptor
    }()
    #endif
    
    lazy var parsedFileStream = fileEventStream.share().map { event -> (FileBrowser.Event, CodeGrid?) in
        switch event {
        case .noSelection:
            return (event, nil)
            
        case let .newSinglePath(path):
            var createdGrid: CodeGrid?
            sceneTransaction {
                self.codeGridParser.withNewGrid(path.url) { plane, newGrid in
                    plane.addGrid(style: .trailingFromLastGrid(newGrid))
                    createdGrid = newGrid
                }
            }
            return (event, createdGrid)
            
        case let .newSingleCommand(path, style):
            var createdGrid: CodeGrid?
            sceneTransaction {
                self.codeGridParser.withNewGrid(path.url) { plane, newGrid in
                    switch style {
                    case .addToRow, .allChildrenInRow:
                        plane.addGrid(style: .trailingFromLastGrid(newGrid))
                    case .inNewRow, .allChildrenInNewRow:
                        plane.addGrid(style: .inNextRow(newGrid))
                    case .inNewPlane, .allChildrenInNewPlane:
                        plane.addGrid(style: .inNextPlane(newGrid))
                    }
                    createdGrid = newGrid
                }
            }
            return (event, createdGrid)
        
        case let .newMultiCommandImmediateChildren(parent, style):
            sceneTransaction {
                switch style {
                case .allChildrenInRow, .addToRow:
                    parent.children().filter(FileBrowser.isFileObserved).forEach { subpath in
                        self.codeGridParser.withNewGrid(subpath.url) { plane, newGrid in
                            plane.addGrid(style: .trailingFromLastGrid(newGrid))
                        }
                    }
                    
                case .inNewRow, .allChildrenInNewRow:
                    parent.children().filter(FileBrowser.isSwiftFile).enumerated().forEach { index, subpath in
                        self.codeGridParser.withNewGrid(subpath.url) { plane, newGrid in
                            if index == 0 {
                                plane.addGrid(style: .inNextRow(newGrid))
                            } else {
                                plane.addGrid(style: .trailingFromLastGrid(newGrid))
                            }
                            
                        }
                    }
                        
                case .inNewPlane, .allChildrenInNewPlane:
                    parent.children().filter(FileBrowser.isSwiftFile).forEach { subpath in
                        self.codeGridParser.withNewGrid(subpath.url) { plane, newGrid in
                            plane.addGrid(style: .inNextPlane(newGrid))
                        }
                    }
                }
            }
            
            return (event, nil)
            
        case let .newMultiCommandRecursiveAll(parent, _):
            self.codeGridParser.__versionTwo__RenderPathAsRoot(parent) { firstGrid in
                DispatchQueue.main.async {
                    sceneTransaction {
                        self.sceneState.rootGeometryNode.addChildNode(firstGrid.rootNode)
                    }
                }
            }
            
            return (event, nil)
        }
        
    }.eraseToAnyPublisher()
    
    

    func attachMouseSink() {
        #if os(OSX)
        SceneLibrary.global.sharedMouse
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] mousePosition in
                self?.newMousePosition(mousePosition)
            }
            .store(in: &cancellables)

        SceneLibrary.global.sharedScroll
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] scrollEvent in
                self?.newScrollEvent(scrollEvent)
            }
            .store(in: &cancellables)

        SceneLibrary.global.sharedMouseDown
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] downEvent in
                self?.newMouseDown(downEvent)
            }
            .store(in: &cancellables)
        #endif
    }
    
    func attachKeyInputSink() {
        #if os(OSX)
        SceneLibrary.global.sharedKeyEvent
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] event in
                self?.newKeyEvent(event)
            }
            .store(in: &cancellables)
        #endif
        
    }

    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
        DispatchQueue.main.async {
            self.attachMouseSink()
            self.attachKeyInputSink()
        }
    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        iteratorY.reset()
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
        bumpNodes(
            allTokensWith(name: name)
        )
    }
	
	func selected(id: SyntaxIdentifier, in source: CodeGridSemanticMap) {
		guard let sheet = source.tokenNodes(id) else {
			print("Missing sheet or semantic info for \(id)")
			return
		}
		
		let isSelected = selectedSheets.toggle(id)
		sceneTransaction {
			sheet.forEach { node in
				node.position = node.position.translated(
					dZ: isSelected ? 25 : -25
				)
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
import FileKit
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
