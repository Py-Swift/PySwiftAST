/// Python expression types
public indirect enum Expression: ASTNode {
    case boolOp(BoolOp)
    case namedExpr(NamedExpr)
    case binOp(BinOp)
    case unaryOp(UnaryOp)
    case lambda(Lambda)
    case ifExp(IfExp)
    case dict(Dict)
    case set(Set)
    case listComp(ListComp)
    case setComp(SetComp)
    case dictComp(DictComp)
    case generatorExp(GeneratorExp)
    case await(Await)
    case yield(Yield)
    case yieldFrom(YieldFrom)
    case compare(Compare)
    case call(Call)
    case formattedValue(FormattedValue)
    case joinedStr(JoinedStr)
    case constant(Constant)
    case attribute(Attribute)
    case subscriptExpr(Subscript)
    case starred(Starred)
    case name(Name)
    case list(List)
    case tuple(Tuple)
    case slice(Slice)
    
    public var lineno: Int { 0 }
    public var colOffset: Int { 0 }
    
    public var endLineno: Int? { nil }
    public var endColOffset: Int? { nil }
}

// MARK: - TreeDisplayable Conformance
extension Expression: TreeDisplayable {
    public func treeLines(indent: String, isLast: Bool) -> [String] {
        let connector = isLast ? TreeDisplay.lastBranch : TreeDisplay.branch
        let childIndent = TreeDisplay.childIndent(for: indent, isLast: isLast)
        var lines: [String] = []
        
        switch self {
        case .boolOp(let boolOp):
            let opName = boolOp.op == .and ? "and" : "or"
            lines.append(indent + connector + "BoolOp (\(opName))")
            lines.append(childIndent + TreeDisplay.lastBranch + "Values: \(boolOp.values.count)")
            
        case .namedExpr(let namedExpr):
            lines.append(indent + connector + "NamedExpr (:=)")
            lines.append(childIndent + TreeDisplay.branch + "Target:")
            let targetLines = namedExpr.target.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: targetLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Value:")
            let valueLines = namedExpr.value.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .binOp(let binOp):
            let opName = operatorName(binOp.op)
            lines.append(indent + connector + "BinOp (\(opName))")
            lines.append(childIndent + TreeDisplay.branch + "Left:")
            let leftLines = binOp.left.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: leftLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Right:")
            let rightLines = binOp.right.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: rightLines)
            
        case .unaryOp(let unaryOp):
            let opName = unaryOperatorName(unaryOp.op)
            lines.append(indent + connector + "UnaryOp (\(opName))")
            lines.append(childIndent + TreeDisplay.lastBranch + "Operand:")
            let operandLines = unaryOp.operand.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: operandLines)
            
        case .lambda(let lambda):
            lines.append(indent + connector + "Lambda")
            lines.append(childIndent + TreeDisplay.branch + "Args: \(lambda.args.args.count)")
            lines.append(childIndent + TreeDisplay.lastBranch + "Body:")
            let bodyLines = lambda.body.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: bodyLines)
            
        case .ifExp(let ifExp):
            lines.append(indent + connector + "IfExp")
            lines.append(childIndent + TreeDisplay.branch + "Test:")
            let testLines = ifExp.test.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: testLines)
            lines.append(childIndent + TreeDisplay.branch + "Body:")
            let bodyLines = ifExp.body.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: bodyLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Orelse:")
            let orelseLines = ifExp.orElse.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: orelseLines)
            
        case .dict(let dict):
            lines.append(indent + connector + "Dict (items: \(dict.keys.count))")
            
        case .set(let set):
            lines.append(indent + connector + "Set (elements: \(set.elts.count))")
            
        case .listComp(let listComp):
            lines.append(indent + connector + "ListComp (generators: \(listComp.generators.count))")
            
        case .setComp(let setComp):
            lines.append(indent + connector + "SetComp (generators: \(setComp.generators.count))")
            
        case .dictComp(let dictComp):
            lines.append(indent + connector + "DictComp (generators: \(dictComp.generators.count))")
            
        case .generatorExp(let genExp):
            lines.append(indent + connector + "GeneratorExp (generators: \(genExp.generators.count))")
            
        case .await(let awaitExpr):
            lines.append(indent + connector + "Await")
            let valueLines = awaitExpr.value.treeLines(indent: childIndent, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .yield(let yieldExpr):
            lines.append(indent + connector + "Yield")
            if let value = yieldExpr.value {
                let valueLines = value.treeLines(indent: childIndent, isLast: true)
                lines.append(contentsOf: valueLines)
            }
            
        case .yieldFrom(let yieldFrom):
            lines.append(indent + connector + "YieldFrom")
            let valueLines = yieldFrom.value.treeLines(indent: childIndent, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .compare(let compare):
            lines.append(indent + connector + "Compare")
            lines.append(childIndent + TreeDisplay.branch + "Left:")
            let leftLines = compare.left.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: leftLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Comparators: \(compare.comparators.count)")
            
        case .call(let call):
            lines.append(indent + connector + "Call")
            lines.append(childIndent + TreeDisplay.branch + "Function:")
            let funcLines = call.fun.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: funcLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Args: \(call.args.count)")
            
        case .formattedValue:
            lines.append(indent + connector + "FormattedValue")
            
        case .joinedStr(let joinedStr):
            lines.append(indent + connector + "JoinedStr (values: \(joinedStr.values.count))")
            
        case .constant(let constant):
            lines.append(indent + connector + "Constant: \(valueDescription(constant.value))")
            
        case .attribute(let attribute):
            lines.append(indent + connector + "Attribute: \(attribute.attr)")
            let valueLines = attribute.value.treeLines(indent: childIndent, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .subscriptExpr(let sub):
            lines.append(indent + connector + "Subscript")
            lines.append(childIndent + TreeDisplay.branch + "Value:")
            let valueLines = sub.value.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: valueLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Slice:")
            let sliceLines = sub.slice.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: sliceLines)
            
        case .starred(let starred):
            lines.append(indent + connector + "Starred")
            let valueLines = starred.value.treeLines(indent: childIndent, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .name(let name):
            lines.append(indent + connector + "Name: \(name.id)")
            
        case .list(let list):
            lines.append(indent + connector + "List (elements: \(list.elts.count))")
            
        case .tuple(let tuple):
            lines.append(indent + connector + "Tuple (elements: \(tuple.elts.count))")
            
        case .slice(let slice):
            lines.append(indent + connector + "Slice")
            if let lower = slice.lower {
                lines.append(childIndent + TreeDisplay.branch + "Lower:")
                let lowerLines = lower.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
                lines.append(contentsOf: lowerLines)
            }
            if let upper = slice.upper {
                lines.append(childIndent + TreeDisplay.branch + "Upper:")
                let upperLines = upper.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: slice.step == nil)
                lines.append(contentsOf: upperLines)
            }
            if let step = slice.step {
                lines.append(childIndent + TreeDisplay.lastBranch + "Step:")
                let stepLines = step.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
                lines.append(contentsOf: stepLines)
            }
        }
        
        return lines
    }
    
    // MARK: - Helper Functions
    
    private func operatorName(_ op: Operator) -> String {
        switch op {
        case .add: return "+"
        case .sub: return "-"
        case .mult: return "*"
        case .matMult: return "@"
        case .div: return "/"
        case .mod: return "%"
        case .pow: return "**"
        case .lShift: return "<<"
        case .rShift: return ">>"
        case .bitOr: return "|"
        case .bitXor: return "^"
        case .bitAnd: return "&"
        case .floorDiv: return "//"
        }
    }
    
    private func unaryOperatorName(_ op: UnaryOperator) -> String {
        switch op {
        case .invert: return "~"
        case .not: return "not"
        case .uAdd: return "+"
        case .uSub: return "-"
        }
    }
    
    private func valueDescription(_ value: ConstantValue) -> String {
        switch value {
        case .none:
            return "None"
        case .bool(let b):
            return b ? "True" : "False"
        case .int(let i):
            return "\(i)"
        case .float(let f):
            return "\(f)"
        case .complex(let real, let imag):
            return "\(real)+\(imag)j"
        case .string(let s):
            return "\"\(s.prefix(50))\""
        case .bytes(let data):
            return "b'<\(data.count) bytes>'"
        case .ellipsis:
            return "..."
        }
    }
}
