import Foundation
import PySwiftAST
import PySwiftCodeGen

func readFile(_ path: String) -> String {
    guard let data = FileManager.default.contents(atPath: path),
          let content = String(data: data, encoding: .utf8) else {
        fputs("Error: Could not read file at \(path)\n", stderr)
        exit(1)
    }
    return content
}

func measure(_ block: () throws -> Void) rethrows -> TimeInterval {
    let start = Date()
    try block()
    return Date().timeIntervalSince(start)
}

enum BenchmarkMode: String {
    case tokenize = "tokenize"           // Tokenizer
    case parse = "parse"                 // Parsing only (pre-tokenized)
    case roundtrip = "roundtrip"         // Full tokenize + parse + codegen
    case codegen = "codegen"             // Code generation only
}

func main() {
    guard CommandLine.arguments.count == 4 else {
        fputs("""
        Usage: pyswift-benchmark <file> <iterations> <mode>
        
        Modes:
          tokenize       - UTF-8 byte-based tokenizer
          parse          - Parser only (pre-tokenized)
          roundtrip      - Full pipeline (tokenize + parse + codegen)
          codegen        - Code generation only (pre-parsed)
        
        Output: JSON array of times in seconds
        
        """, stderr)
        exit(1)
    }
    
    let filePath = CommandLine.arguments[1]
    guard let iterations = Int(CommandLine.arguments[2]) else {
        fputs("Error: iterations must be an integer\n", stderr)
        exit(1)
    }
    guard let mode = BenchmarkMode(rawValue: CommandLine.arguments[3]) else {
        fputs("Error: invalid mode '\(CommandLine.arguments[3])'\n", stderr)
        exit(1)
    }
    
    let source = readFile(filePath)
    var times: [TimeInterval] = []
    
    // Pre-tokenize for parse/codegen modes
    var cachedTokens: [Token] = []
    var cachedAST: Module?
    
    if mode == .parse || mode == .codegen {
        // Pre-tokenize for parse/codegen modes
        cachedTokens = try! Tokenizer(source: source).tokenize()
    }
    
    if mode == .codegen {
        // Pre-parse for codegen-only mode
        cachedAST = try! Parser(tokens: cachedTokens).parse()
    }
    
    // Run benchmark
    for _ in 0..<iterations {
        let time: TimeInterval
        
        switch mode {
        case .tokenize:
            // UTF-8 byte-based tokenizer
            time = measure {
                _ = try! Tokenizer(source: source).tokenize()
            }
            
        case .parse:
            // Parser only (using cached tokens)
            time = measure {
                _ = try! Parser(tokens: cachedTokens).parse()
            }
            
        case .roundtrip:
            // Full pipeline
            time = measure {
                let tokens = try! Tokenizer(source: source).tokenize()
                let ast = try! Parser(tokens: tokens).parse()
                _ = generatePythonCode(from: ast)
            }
            
        case .codegen:
            // Code generation only
            time = measure {
                _ = generatePythonCode(from: cachedAST!)
            }
        }
        
        times.append(time)
    }
    
    // Output as JSON array
    let jsonData = try! JSONSerialization.data(withJSONObject: times, options: [])
    print(String(data: jsonData, encoding: .utf8)!)
}

main()
