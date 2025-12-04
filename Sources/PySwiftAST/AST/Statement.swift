/// Python statement types
public indirect enum Statement: ASTNode, Sendable {
    case functionDef(FunctionDef)
    case asyncFunctionDef(AsyncFunctionDef)
    case classDef(ClassDef)
    case returnStmt(Return)
    case delete(Delete)
    case assign(Assign)
    case augAssign(AugAssign)
    case annAssign(AnnAssign)
    case forStmt(For)
    case asyncFor(AsyncFor)
    case whileStmt(While)
    case ifStmt(If)
    case withStmt(With)
    case asyncWith(AsyncWith)
    case match(Match)
    case raise(Raise)
    case tryStmt(Try)
    case tryStar(TryStar)
    case assertStmt(Assert)
    case importStmt(Import)
    case importFrom(ImportFrom)
    case global(Global)
    case nonlocal(Nonlocal)
    case expr(Expr)
    case pass(Pass)
    case breakStmt(Break)
    case continueStmt(Continue)
    case blank(Blank) // Formatting control - generates blank lines
    case typeAlias(TypeAlias) // Python 3.12+
    
    public var lineno: Int {
        switch self {
        case .functionDef(let node): return node.lineno
        case .asyncFunctionDef(let node): return node.lineno
        case .classDef(let node): return node.lineno
        case .returnStmt(let node): return node.lineno
        case .delete(let node): return node.lineno
        case .assign(let node): return node.lineno
        case .augAssign(let node): return node.lineno
        case .annAssign(let node): return node.lineno
        case .forStmt(let node): return node.lineno
        case .asyncFor(let node): return node.lineno
        case .whileStmt(let node): return node.lineno
        case .ifStmt(let node): return node.lineno
        case .withStmt(let node): return node.lineno
        case .asyncWith(let node): return node.lineno
        case .match(let node): return node.lineno
        case .raise(let node): return node.lineno
        case .tryStmt(let node): return node.lineno
        case .tryStar(let node): return node.lineno
        case .assertStmt(let node): return node.lineno
        case .importStmt(let node): return node.lineno
        case .importFrom(let node): return node.lineno
        case .global(let node): return node.lineno
        case .nonlocal(let node): return node.lineno
        case .expr(let node): return node.lineno
        case .pass(let node): return node.lineno
        case .breakStmt(let node): return node.lineno
        case .continueStmt(let node): return node.lineno
        case .blank(let node): return node.lineno
        case .typeAlias(let node): return node.lineno
        }
    }
    
    public var colOffset: Int {
        // Similar pattern for colOffset
        return 0 // Simplified for brevity
    }
    
    public var endLineno: Int? {
        switch self {
        case .functionDef(let node): return node.endLineno
        case .asyncFunctionDef(let node): return node.endLineno
        case .classDef(let node): return node.endLineno
        case .returnStmt(let node): return node.endLineno
        case .delete(let node): return node.endLineno
        case .assign(let node): return node.endLineno
        case .augAssign(let node): return node.endLineno
        case .annAssign(let node): return node.endLineno
        case .forStmt(let node): return node.endLineno
        case .asyncFor(let node): return node.endLineno
        case .whileStmt(let node): return node.endLineno
        case .ifStmt(let node): return node.endLineno
        case .withStmt(let node): return node.endLineno
        case .asyncWith(let node): return node.endLineno
        case .match(let node): return node.endLineno
        case .raise(let node): return node.endLineno
        case .tryStmt(let node): return node.endLineno
        case .tryStar(let node): return node.endLineno
        case .assertStmt(let node): return node.endLineno
        case .importStmt(let node): return node.endLineno
        case .importFrom(let node): return node.endLineno
        case .global(let node): return node.endLineno
        case .nonlocal(let node): return node.endLineno
        case .expr(let node): return node.endLineno
        case .pass(let node): return node.endLineno
        case .breakStmt(let node): return node.endLineno
        case .continueStmt(let node): return node.endLineno
        case .blank(let node): return node.endLineno
        case .typeAlias(let node): return node.endLineno
        }
    }
    
    public var endColOffset: Int? {
        switch self {
        case .functionDef(let node): return node.endColOffset
        case .asyncFunctionDef(let node): return node.endColOffset
        case .classDef(let node): return node.endColOffset
        case .returnStmt(let node): return node.endColOffset
        case .delete(let node): return node.endColOffset
        case .assign(let node): return node.endColOffset
        case .augAssign(let node): return node.endColOffset
        case .annAssign(let node): return node.endColOffset
        case .forStmt(let node): return node.endColOffset
        case .asyncFor(let node): return node.endColOffset
        case .whileStmt(let node): return node.endColOffset
        case .ifStmt(let node): return node.endColOffset
        case .withStmt(let node): return node.endColOffset
        case .asyncWith(let node): return node.endColOffset
        case .match(let node): return node.endColOffset
        case .raise(let node): return node.endColOffset
        case .tryStmt(let node): return node.endColOffset
        case .tryStar(let node): return node.endColOffset
        case .assertStmt(let node): return node.endColOffset
        case .importStmt(let node): return node.endColOffset
        case .importFrom(let node): return node.endColOffset
        case .global(let node): return node.endColOffset
        case .nonlocal(let node): return node.endColOffset
        case .expr(let node): return node.endColOffset
        case .pass(let node): return node.endColOffset
        case .breakStmt(let node): return node.endColOffset
        case .continueStmt(let node): return node.endColOffset
        case .blank(let node): return node.endColOffset
        case .typeAlias(let node): return node.endColOffset
        }
    }
}

// MARK: - TreeDisplayable Conformance
extension Statement: TreeDisplayable {
    public func treeLines(indent: String, isLast: Bool) -> [String] {
        let connector = isLast ? TreeDisplay.lastBranch : TreeDisplay.branch
        let childIndent = TreeDisplay.childIndent(for: indent, isLast: isLast)
        var lines: [String] = []
        
        switch self {
        case .functionDef(let funcDef):
            lines.append(indent + connector + "FunctionDef: \(funcDef.name)")
            if !funcDef.args.args.isEmpty {
                lines.append(childIndent + TreeDisplay.branch + "Args: \(funcDef.args.args.count)")
            }
            if !funcDef.decoratorList.isEmpty {
                lines.append(childIndent + TreeDisplay.branch + "Decorators: \(funcDef.decoratorList.count)")
            }
            lines.append(childIndent + TreeDisplay.lastBranch + "Body: \(funcDef.body.count) statements")
            for (index, stmt) in funcDef.body.enumerated() {
                let stmtIsLast = index == funcDef.body.count - 1
                let stmtLines = stmt.treeLines(indent: childIndent + TreeDisplay.space, isLast: stmtIsLast)
                lines.append(contentsOf: stmtLines)
            }
            
        case .asyncFunctionDef(let funcDef):
            lines.append(indent + connector + "AsyncFunctionDef: \(funcDef.name)")
            lines.append(childIndent + TreeDisplay.lastBranch + "Body: \(funcDef.body.count) statements")
            for (index, stmt) in funcDef.body.enumerated() {
                let stmtIsLast = index == funcDef.body.count - 1
                let stmtLines = stmt.treeLines(indent: childIndent + TreeDisplay.space, isLast: stmtIsLast)
                lines.append(contentsOf: stmtLines)
            }
            
        case .classDef(let classDef):
            lines.append(indent + connector + "ClassDef: \(classDef.name)")
            if !classDef.bases.isEmpty {
                lines.append(childIndent + TreeDisplay.branch + "Bases: \(classDef.bases.count)")
            }
            if !classDef.decoratorList.isEmpty {
                lines.append(childIndent + TreeDisplay.branch + "Decorators: \(classDef.decoratorList.count)")
            }
            lines.append(childIndent + TreeDisplay.lastBranch + "Body: \(classDef.body.count) statements")
            
        case .returnStmt(let ret):
            lines.append(indent + connector + "Return")
            if let value = ret.value {
                let exprLines = value.treeLines(indent: childIndent, isLast: true)
                lines.append(contentsOf: exprLines)
            }
            
        case .delete(let del):
            lines.append(indent + connector + "Delete (targets: \(del.targets.count))")
            
        case .assign(let assign):
            lines.append(indent + connector + "Assign")
            lines.append(childIndent + TreeDisplay.branch + "Targets: \(assign.targets.count)")
            for target in assign.targets {
                let targetLines = target.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
                lines.append(contentsOf: targetLines)
            }
            lines.append(childIndent + TreeDisplay.lastBranch + "Value:")
            let valueLines = assign.value.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .augAssign(let augAssign):
            lines.append(indent + connector + "AugAssign")
            lines.append(childIndent + TreeDisplay.branch + "Target:")
            let targetLines = augAssign.target.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: targetLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Value:")
            let valueLines = augAssign.value.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: valueLines)
            
        case .annAssign(let annAssign):
            lines.append(indent + connector + "AnnAssign")
            lines.append(childIndent + TreeDisplay.branch + "Target:")
            let targetLines = annAssign.target.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: targetLines)
            lines.append(childIndent + TreeDisplay.branch + "Annotation:")
            let annotLines = annAssign.annotation.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: annAssign.value == nil)
            lines.append(contentsOf: annotLines)
            if let value = annAssign.value {
                lines.append(childIndent + TreeDisplay.lastBranch + "Value:")
                let valueLines = value.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
                lines.append(contentsOf: valueLines)
            }
            
        case .forStmt(let forStmt):
            lines.append(indent + connector + "For")
            lines.append(childIndent + TreeDisplay.branch + "Target:")
            let targetLines = forStmt.target.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: targetLines)
            lines.append(childIndent + TreeDisplay.branch + "Iter:")
            let iterLines = forStmt.iter.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: iterLines)
            lines.append(childIndent + TreeDisplay.branch + "Body: \(forStmt.body.count) statements")
            if !forStmt.orElse.isEmpty {
                lines.append(childIndent + TreeDisplay.lastBranch + "Orelse: \(forStmt.orElse.count) statements")
            }
            
        case .asyncFor:
            lines.append(indent + connector + "AsyncFor")
            
        case .whileStmt(let whileStmt):
            lines.append(indent + connector + "While")
            lines.append(childIndent + TreeDisplay.branch + "Test:")
            let testLines = whileStmt.test.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: testLines)
            lines.append(childIndent + TreeDisplay.branch + "Body: \(whileStmt.body.count) statements")
            if !whileStmt.orElse.isEmpty {
                lines.append(childIndent + TreeDisplay.lastBranch + "Orelse: \(whileStmt.orElse.count) statements")
            }
            
        case .ifStmt(let ifStmt):
            lines.append(indent + connector + "If")
            lines.append(childIndent + TreeDisplay.branch + "Test:")
            let testLines = ifStmt.test.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: testLines)
            lines.append(childIndent + TreeDisplay.branch + "Body: \(ifStmt.body.count) statements")
            if !ifStmt.orElse.isEmpty {
                lines.append(childIndent + TreeDisplay.lastBranch + "Orelse: \(ifStmt.orElse.count) statements")
            }
            
        case .withStmt(let withStmt):
            lines.append(indent + connector + "With (items: \(withStmt.items.count))")
            
        case .asyncWith(let withStmt):
            lines.append(indent + connector + "AsyncWith (items: \(withStmt.items.count))")
            
        case .match(let matchStmt):
            lines.append(indent + connector + "Match")
            lines.append(childIndent + TreeDisplay.branch + "Subject:")
            let subjectLines = matchStmt.subject.treeLines(indent: childIndent + TreeDisplay.verticalLine, isLast: false)
            lines.append(contentsOf: subjectLines)
            lines.append(childIndent + TreeDisplay.lastBranch + "Cases: \(matchStmt.cases.count)")
            
        case .raise(let raiseStmt):
            lines.append(indent + connector + "Raise")
            if let exc = raiseStmt.exc {
                let excLines = exc.treeLines(indent: childIndent, isLast: true)
                lines.append(contentsOf: excLines)
            }
            
        case .tryStmt(let tryStmt):
            lines.append(indent + connector + "Try")
            lines.append(childIndent + TreeDisplay.branch + "Body: \(tryStmt.body.count) statements")
            lines.append(childIndent + TreeDisplay.lastBranch + "Handlers: \(tryStmt.handlers.count)")
            
        case .tryStar(let tryStmt):
            lines.append(indent + connector + "TryStar (handlers: \(tryStmt.handlers.count))")
            
        case .assertStmt(let assertStmt):
            lines.append(indent + connector + "Assert")
            lines.append(childIndent + TreeDisplay.lastBranch + "Test:")
            let testLines = assertStmt.test.treeLines(indent: childIndent + TreeDisplay.space, isLast: true)
            lines.append(contentsOf: testLines)
            
        case .importStmt(let importStmt):
            lines.append(indent + connector + "Import")
            for (index, alias) in importStmt.names.enumerated() {
                let aliasIsLast = index == importStmt.names.count - 1
                let aliasConnector = aliasIsLast ? TreeDisplay.lastBranch : TreeDisplay.branch
                lines.append(childIndent + aliasConnector + "\(alias.name)")
            }
            
        case .importFrom(let importFrom):
            let moduleName = importFrom.module ?? "."
            lines.append(indent + connector + "ImportFrom: \(moduleName)")
            for (index, alias) in importFrom.names.enumerated() {
                let aliasIsLast = index == importFrom.names.count - 1
                let aliasConnector = aliasIsLast ? TreeDisplay.lastBranch : TreeDisplay.branch
                lines.append(childIndent + aliasConnector + "\(alias.name)")
            }
            
        case .global(let globalStmt):
            lines.append(indent + connector + "Global: \(globalStmt.names.joined(separator: ", "))")
            
        case .nonlocal(let nonlocalStmt):
            lines.append(indent + connector + "Nonlocal: \(nonlocalStmt.names.joined(separator: ", "))")
            
        case .expr(let exprStmt):
            lines.append(indent + connector + "Expr")
            let exprLines = exprStmt.value.treeLines(indent: childIndent, isLast: true)
            lines.append(contentsOf: exprLines)
            
        case .pass:
            lines.append(indent + connector + "Pass")
            
        case .breakStmt:
            lines.append(indent + connector + "Break")
            
        case .continueStmt:
            lines.append(indent + connector + "Continue")
            
        case .blank(let blank):
            lines.append(indent + connector + "Blank(\(blank.count))")
            
        case .typeAlias(let typeAlias):
            lines.append(indent + connector + "TypeAlias: \(typeAlias.name)")
        }
        
        return lines
    }
}
