import Foundation
import PySwiftAST
import PySwiftCodeGen

// Simple inline profiler to measure function calls
class SimpleProfiler {
    struct Entry {
        var name: String
        var count: Int
        var totalTime: TimeInterval
        var selfTime: TimeInterval
    }
    
    static var entries: [String: Entry] = [:]
    static var callStack: [(name: String, startTime: Date)] = []
    
    static func measure<T>(_ name: String, _ block: () throws -> T) rethrows -> T {
        let start = Date()
        callStack.append((name, start))
        
        defer {
            let elapsed = Date().timeIntervalSince(start)
            callStack.removeLast()
            
            if entries[name] == nil {
                entries[name] = Entry(name: name, count: 0, totalTime: 0, selfTime: 0)
            }
            entries[name]!.count += 1
            entries[name]!.totalTime += elapsed
            
            // Self time: subtract time spent in child calls
            let childTime = callStack.reduce(0.0) { sum, entry in
                if entry.name != name {
                    return sum + Date().timeIntervalSince(entry.startTime)
                }
                return sum
            }
            entries[name]!.selfTime += (elapsed - childTime)
        }
        
        return try block()
    }
    
    static func report() {
        let sorted = entries.values.sorted { $0.totalTime > $1.totalTime }
        
        print("\n" + String(repeating: "=", count: 80))
        print("INLINE PROFILER REPORT")
        print(String(repeating: "=", count: 80))
        print(String(format: "%-40s %8s %12s %12s %8s", 
                     "Function", "Calls", "Total (ms)", "Self (ms)", "% Time"))
        print(String(repeating: "-", count: 80))
        
        let totalTime = sorted.first?.totalTime ?? 1.0
        
        for entry in sorted.prefix(20) {
            let pct = (entry.totalTime / totalTime) * 100
            print(String(format: "%-40s %8d %12.3f %12.3f %7.1f%%", 
                         String(entry.name.prefix(40)),
                         entry.count,
                         entry.totalTime * 1000,
                         entry.selfTime * 1000,
                         pct))
        }
        print(String(repeating: "=", count: 80))
    }
}

// Instrumented Parser wrapper
class InstrumentedParser {
    let parser: Parser
    
    init(tokens: [Token]) {
        self.parser = Parser(tokens: tokens)
    }
    
    func parse() throws -> Module {
        return try SimpleProfiler.measure("Parser.parse") {
            try parser.parse()
        }
    }
}

func readFile(_ path: String) -> String {
    guard let data = FileManager.default.contents(atPath: path),
          let content = String(data: data, encoding: .utf8) else {
        fputs("Error: Could not read file at \(path)\n", stderr)
        exit(1)
    }
    return content
}

func main() {
    guard CommandLine.arguments.count >= 2 else {
        fputs("""
        Usage: profile-inline <file> [iterations]
        
        Runs inline profiling on parser to identify hot functions
        
        """, stderr)
        exit(1)
    }
    
    let filePath = CommandLine.arguments[1]
    let iterations = CommandLine.arguments.count >= 3 ? Int(CommandLine.arguments[2]) ?? 10 : 10
    
    let source = readFile(filePath)
    
    print("Profiling parser with inline measurements...")
    print("File: \(filePath)")
    print("Iterations: \(iterations)\n")
    
    // Pre-tokenize
    let tokens = try! Tokenizer(source: source).tokenize()
    print("Tokens: \(tokens.count)\n")
    
    // Run profiled parsing
    for i in 0..<iterations {
        if i % 10 == 0 {
            print("Progress: \(i)/\(iterations)...", terminator: "\r")
            fflush(stdout)
        }
        
        let parser = InstrumentedParser(tokens: tokens)
        _ = try! parser.parse()
    }
    
    print("\nProfiling complete!\n")
    
    // Report
    SimpleProfiler.report()
}

main()
