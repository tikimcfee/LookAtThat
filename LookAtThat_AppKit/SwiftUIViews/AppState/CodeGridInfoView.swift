//
//  CodeGridInfoView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/17/22.
//

import SwiftUI
import Combine
import SceneKit

// MARK: - State

class CodeGridInfoViewState: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    @Published var selection: Selection = .none
    
    init() {
        CodePagesController.shared.hover
            .$state.sink(receiveValue: { state in
                if let node = state.hoveredNode {
                    self.selection = .node(node)
                }
            }).store(in: &cancellables)
        
        CodePagesController.shared.editorState
            .$rootMode.sink(receiveValue: { mode in
                switch mode {
                case let .editing(grid, _):
                    self.selection = .single(grid)
                default:
                    self.selection = .none
                }
            }).store(in: &cancellables)
    }
}

extension CodeGridInfoViewState {
    enum Selection {
        case none
        case single(CodeGrid)
        case node(SCNNode)
    }
}

// MARK: - View

struct CodeGridInfoView: View {
    @StateObject var state = CodeGridInfoViewState()
    
    var body: some View {
        rootView
            .padding()
            .fixedSize()
    }
    
    @ViewBuilder
    var rootView: some View {
        switch state.selection {
        case .none:
            Text("No Grid Selected")
        case .single(let grid):
            singleGridView(grid)
        case .node(let node):
            singleNodeView(node)
        }
    }
    
    @ViewBuilder
    func singleGridView(_ grid: CodeGrid) -> some View {
        CodeGridInfoViewSingle(
            state: CodeGridInfoViewSingleState(codeGrid: grid)
        )
    }
    
    @ViewBuilder
    func singleNodeView(_ node: SCNNode) -> some View {
        VStack(alignment: .leading) {
            ForEach(parentsFrom(node: node), id: \.hashValue) { node in
                HStack(alignment: .firstTextBaseline) {
                    Text("- \(node.name ?? "no_name")")
                    VStack(alignment: .leading) {
                        Text("pos = \(position(of: node))")
                            .onTapGesture { addNodeAt(node.worldPosition) }
                        Text("pos_w = \(worldPosition(of: node))")
                        Text("bounds= \(worldBounds(of: node))")
                    }
                }
            }
        }
    }
    
    func makePointerNode() -> SCNNode {
        let node = SCNNode()
        node.geometry = SCNSphere(radius: 4.0)
        node.geometry?.materials.first?.diffuse.contents = NSUIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        return node
    }
    
    func addNodeAt(_ pos: SCNVector3) {
        let pointer = makePointerNode()
        pointer.position = pos
        CodePagesController.shared.sceneState
            .rootGeometryNode
            .addChildNode(pointer)
    }
    
    var root: SCNNode {
        CodePagesController.shared.sceneState.rootGeometryNode.parent!
    }
    
    func position(of node: SCNNode) -> String {
        "\(node.position.x), \(node.position.y), \(node.position.z)"
    }
    
    func worldPosition(of node: SCNNode) -> String {
        "\(node.worldPosition.x), \(node.worldPosition.y), \(node.worldPosition.z)"
    }
    
    func worldBounds(of node: SCNNode) -> String {
        "\(node.worldBoundsMin)\n\(node.worldBoundsMax)"
    }
    
    func position(of node: SCNNode, converted: SCNNode?) -> String {
        let converted = node.convertPosition(node.position, to: converted)
        return "\(converted.x), \(converted.y), \(converted.z)"
    }
    
    func parentsFrom(node: SCNNode) -> [SCNNode] {
        var target = node
        var parents = [node]
        while let parent = target.parent {
            parents.append(parent)
            target = parent
        }
        return parents
    }
}

class CodeGridInfoViewSingleState: ObservableObject {
    @Published var node = SCNNode()
    @Published var labels = [(String, String)]()
    
    var tokens = Set<NSKeyValueObservation>()
    var cancellables = Set<AnyCancellable>()
    let codeGrid: CodeGrid
    let formatter = NumberFormatter()
    
    init(
        codeGrid: CodeGrid
    ) {
        self.codeGrid = codeGrid
        setupObservation()
    }
    
    func setupObservation() {
        formatter.allowsFloats = true
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 8
        
        [
            codeGrid.rootNode.publisher(for: \.position).sink { _ in self.onNodeChanged() },
            codeGrid.rootNode.publisher(for: \.orientation).sink { _ in self.onNodeChanged() }
        ].forEach { $0.store(in: &cancellables) }
    }
    
    func onNodeChanged() {
        node = codeGrid.rootNode
        labels = buildLabels()
        
    }
    
    private func buildLabels() -> [(String, String)] {
        [
            ("position-x", formatter.string(from: node.position.x as NSNumber)),
            ("position-y", formatter.string(from: node.position.y as NSNumber)),
            ("position-z", formatter.string(from: node.position.z as NSNumber)),
            ("orient-x", formatter.string(from: node.orientation.x as NSNumber)),
            ("orient-y", formatter.string(from: node.orientation.y as NSNumber)),
            ("orient-z", formatter.string(from: node.orientation.z as NSNumber)),
            ("orient-w", formatter.string(from: node.orientation.w as NSNumber))
        ].compactMap { tuple -> (String, String)? in
            guard let formatted = tuple.1 else { return nil }
            return (tuple.0, formatted)
        }
    }
}

struct CodeGridInfoViewSingle: View {
    @StateObject var state: CodeGridInfoViewSingleState
    
    let inputWidth = 128.0
    let labelWidth = 96.0
    
    var body: some View {
        nodeInfoView
            .fixedSize()
    }
    
    @ViewBuilder
    var nodeInfoView: some View {
        VStack(alignment: .leading) {
            Text(state.codeGrid.fileName)
                .bold()
            Text(state.codeGrid.sourcePath?.description ?? "...")
                .underline()
            
            Divider().frame(maxWidth: 256)
            
            VStack {
                Text("Root Node")
                VStack(alignment: .leading) {
                    ForEach(state.labels, id: \.0.self) { label in
                        HStack {
                            Text(label.0).frame(minWidth: labelWidth, alignment: .trailing)
                            Text(" | ")
                            Text(label.1).frame(width: inputWidth, alignment: .leading)
                        }
                    }
                }
                
                Button("Bump node", action: {
                    state.codeGrid.rootNode.translate(dX: 10)
                })
            }
        }
    }
}

// MARK: - Previews

struct CodeGridInfoView_Previews: PreviewProvider {
    static let sourceString = """
func helloWorld() {
  let test = ""
  let another = "X"
  let somethingCrazy: () -> Void = { [weak self] in
     print("Hello, world!")
  }
  somethingCrazy()
}
"""
    
    static var sourceGrid: CodeGrid = {
        let parser = CodeGridParser()
        let grid = parser.renderGrid(sourceString)!
        grid.fileName = "Raw Source File"
        grid.sourcePath = URL(string: "/usr/bin/bashable/fizzbuzzer")
        grid.rootNode.translate(dX: -12.33112312313, dY: 231.22000999, dZ: -0.23123312)
        return grid
    }()
    
    static let infoState: CodeGridInfoViewState = {
        let infoState = CodeGridInfoViewState()
        infoState.selection = .single(sourceGrid)
        return infoState
    }()
    
    static var previews: some View {
        CodeGridInfoView(state: infoState)
    }
}
