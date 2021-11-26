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
	lazy var hoverStream = $hoveredToken.share().eraseToAnyPublisher()
    
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
    }
    
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
    
    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
#if os(OSX)
        DispatchQueue.main.async {
            self.macosCompat.attachMouseSink()
            self.macosCompat.attachKeyInputSink()
        }
#endif
    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        // Clear out all the grids and thingsb
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
