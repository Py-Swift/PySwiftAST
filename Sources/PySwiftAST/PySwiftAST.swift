// The Swift Programming Language
// https://docs.swift.org/swift-book

/// PySwiftAST - A Python 3.13 AST parser written in Swift
/// This library provides tools to parse Python code into an Abstract Syntax Tree

/// Parse Python source code into an AST
public func parsePython(_ source: String) throws -> Module {
    let tokenizer = Tokenizer(source: source)
    let tokens = try tokenizer.tokenize()
    let parser = Parser(tokens: tokens)
    return try parser.parse()
}

/// Tokenize Python source code
public func tokenizePython(_ source: String) throws -> [Token] {
    let tokenizer = Tokenizer(source: source)
    return try tokenizer.tokenize()
}

/// Display an AST as a tree structure
public func displayAST(_ module: Module) -> String {
    return ASTTreeDisplay.display(module)
}
