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
    let codeSheetParser: CodeSheetParserV2
    let codeGridParser: CodeGridParser

    @Published var selectedSheet: CodeSheet?
    lazy var sheetStream = $selectedSheet.share().eraseToAnyPublisher()

    var cancellables = Set<AnyCancellable>()

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.codeGridParser = CodeGridParser()
        self.codeSheetParser = CodeSheetParserV2(wordNodeBuilder)
        super.init(sceneView: sceneView)
    }

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

    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
        DispatchQueue.main.async {
            self.attachMouseSink()
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

typealias RenderDirectoryHandler = ([ParsingState]) -> Void

extension CodePagesController {

    func selected(name: String) {
        bumpNodes(
            allTokensWith(name: name)
        )
    }

    func selected(id: SyntaxIdentifier, in source: OrganizedSourceInfo) {
        guard let sheet = source[id] else {
            print("Missing sheet or semantic info for \(id)")
            return
        }

        let isSelected = selectedSheets.toggle(id)
        sceneTransaction {
            sheet.containerNode.position =
                sheet.containerNode.position.translated(
                    dZ: isSelected ? 25 : -25
                )
        }
    }
	
	func selected(id: SyntaxIdentifier, in source: CodeGridAssociations) {
		guard let sheet = source[id] else {
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

    func renderSyntax(_ handler: @escaping (CodeGridAssociations) -> Void) {
        requestSourceFile { fileUrl in
            self.workerQueue.async {
                guard let grid = self.codeGridParser.renderGrid(fileUrl) else { return }
				
				handler(grid.codeGridInfo)
                
                sceneTransaction {
                    self.sceneState.rootGeometryNode.addChildNode(grid.rootNode)
                }
            }
        }
    }

    func renderDirectory(_ handler: @escaping RenderDirectoryHandler) {
        requestSourceDirectory{ directory in
            self.workerQueue.async {
                self.codeSheetParser.parseDirectory(directory, in: self.sceneState, handler)
            }
        }
    }
}

// MARK: File loading
extension CodePagesController {
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
