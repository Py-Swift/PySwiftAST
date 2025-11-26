import Foundation
import PySwiftAST
import PySwiftCodeGen

let args = CommandLine.arguments
guard args.count >= 4 else {
    print("Usage: pyswift-benchmark <file> <iterations> <mode>")
    print("  mode: parse | roundtrip | tokenize")
    exit(1)
}

let filePath = args[1]
let iterations = Int(args[2]) ?? 100
let mode = args[3]

guard let source = try? String(contentsOfFile: filePath) else {
    print("Error: Could not read file")
    exit(1)
}

// Tokenize once (we're benchmarking parsing, not tokenization)
let tokenizer = Tokenizer(source: source)
let tokens: [Token]
do {
    tokens = try tokenizer.tokenize()
} catch {
    print("Error: Tokenization failed: \(error)")
    exit(1)
}

var times: [Double] = []

if mode == "tokenize" {
    // Benchmark UTF-8 tokenizer
    // Warmup
    for _ in 0..<10 {
        _ = try? Tokenizer(source: source).tokenize()
    }
    
    for _ in 0..<iterations {
        let start = Date()
        _ = try? Tokenizer(source: source).tokenize()
        let end = Date()
        times.append(end.timeIntervalSince(start))
    }
} else if mode == "parse" {
    // Warmup
    for _ in 0..<10 {
        _ = try? Parser(tokens: tokens).parse()
    }
    
    // Benchmark parsing only
    for _ in 0..<iterations {
        let start = Date()
        _ = try? Parser(tokens: tokens).parse()
        let end = Date()
        times.append(end.timeIntervalSince(start))
    }
} else if mode == "roundtrip" {
    // Warmup
    for _ in 0..<10 {
        if let module = try? Parser(tokens: tokens).parse() {
            let generated = generatePythonCode(from: module)
            let generatedTokens = try? Tokenizer(source: generated).tokenize()
            _ = generatedTokens.flatMap { try? Parser(tokens: $0).parse() }
        }
    }
    
    // Benchmark full round-trip: parse → generate → reparse
    for _ in 0..<iterations {
        let start = Date()
        if let module = try? Parser(tokens: tokens).parse() {
            let generated = generatePythonCode(from: module)
            let generatedTokens = try? Tokenizer(source: generated).tokenize()
            _ = generatedTokens.flatMap { try? Parser(tokens: $0).parse() }
        }
        let end = Date()
        times.append(end.timeIntervalSince(start))
    }
} else {
    print("Error: Invalid mode '\(mode)'. Use 'parse', 'roundtrip', or 'tokenize'")
    exit(1)
}

// Output as JSON
let jsonData = try! JSONSerialization.data(withJSONObject: times)
print(String(data: jsonData, encoding: .utf8)!)
