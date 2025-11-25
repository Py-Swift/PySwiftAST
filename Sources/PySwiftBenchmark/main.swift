import Foundation
import PySwiftAST

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: pyswift-benchmark <file> <iterations>")
    exit(1)
}

let filePath = args[1]
let iterations = Int(args[2]) ?? 100

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

// Warmup
for _ in 0..<10 {
    _ = try? Parser(tokens: tokens).parse()
}

// Benchmark
var times: [Double] = []
for _ in 0..<iterations {
    let start = Date()
    _ = try? Parser(tokens: tokens).parse()
    let end = Date()
    times.append(end.timeIntervalSince(start))
}

// Output as JSON
let jsonData = try! JSONSerialization.data(withJSONObject: times)
print(String(data: jsonData, encoding: .utf8)!)
