import Foundation
import AST
import Parser
import Source

class Queue<Element> {
    var items = [Element]()
    func enqueue(_ item: Element) {
        items.append(item)
    }
    func dequeue() -> Element? {
        return items.first != nil ? items.removeFirst() : nil
    }
    func peek() -> Element? {
        return items.first
    }
}

typealias SourceTreeKey = Int
typealias SourceTreeValue = Queue<ASTNode>
typealias SourceTree = [SourceTreeKey:SourceTreeValue]
typealias SourceTreePair = (SourceTreeKey, SourceTreeValue)
typealias SourceTreeList = [(SourceTreeKey, SourceTreeValue)]

protocol VisitorDelegate: AnyObject {
    func didVisit(_ node: ASTNode)
}

class AbstractSyntaxTreeVisitorMuxer: ASTVisitor {
    weak var delegate: VisitorDelegate?

    var sourceLocations = SourceTree()
    var sortedSourceLocations: SourceTreeList {
        sourceLocations.sorted { $0.key < $1.key }
    }

    var orderedStatements = [Source.SourceRange:ASTNode]()

    init(_ delegate: VisitorDelegate? = nil) {
        self.delegate = delegate
    }

    func nodeVisited(_ node: ASTNode) {
        let stack = sourceLocations[node.sourceLocation.line] ?? {
            let stack = SourceTreeValue()
            sourceLocations[node.sourceLocation.line] = stack
            return stack
        }()
        stack.enqueue(node)
        delegate?.didVisit(node)
    }

    func visit(_ node: TopLevelDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: CodeBlock) throws -> Bool {
        nodeVisited(node)
        return true
    }

    // Declarations

    func visit(_ node: ClassDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ConstantDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: DeinitializerDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: EnumDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ExtensionDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: FunctionDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ImportDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: InitializerDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: OperatorDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: PrecedenceGroupDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ProtocolDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: StructDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SubscriptDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: TypealiasDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: VariableDeclaration) throws -> Bool {
        nodeVisited(node)
        return true
    }

    // Statements

    func visit(_ node: BreakStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: CompilerControlStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ContinueStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: DeferStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: DoStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: FallthroughStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ForInStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: GuardStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: IfStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: LabeledStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: RepeatWhileStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ReturnStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SwitchStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ThrowStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: WhileStatement) throws -> Bool {
        nodeVisited(node)
        return true
    }

    // Expressions

    func visit(_ node: AssignmentOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: BinaryOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ClosureExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ExplicitMemberExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ForcedValueExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: FunctionCallExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: IdentifierExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ImplicitMemberExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: InOutExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: InitializerExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: KeyPathStringExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: LiteralExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: OptionalChainingExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: ParenthesizedExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: PostfixOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: PostfixSelfExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: PrefixOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SelectorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SelfExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SequenceExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SubscriptExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: SuperclassExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: TernaryConditionalOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: TryOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: TupleExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: TypeCastingOperatorExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
    func visit(_ node: WildcardExpression) throws -> Bool {
        nodeVisited(node)
        return true
    }
}
