#!/usr/bin/env swift

import Foundation

struct TestFile {
    let name: String
    let path: String
}

let testFiles = [
    TestFile(name: "API Client", path: "Tests/PySwiftASTTests/Resources/test_files/api_client.py"),
    TestFile(name: "Parser Combinators", path: "Tests/PySwiftASTTests/Resources/test_files/parser_combinators.py"),
    TestFile(name: "Database ORM", path: "Tests/PySwiftASTTests/Resources/test_files/database_orm.py"),
    TestFile(name: "State Machine", path: "Tests/PySwiftASTTests/Resources/test_files/state_machine.py")
]

print("Testing Real-World Python Files")
print("================================\n")

for testFile in testFiles {
    print("📄 \(testFile.name)")
    print("   Path: \(testFile.path)")
    
    guard let source = try? String(contentsOfFile: testFile.path) else {
        print("   ❌ Could not read file\n")
        continue
    }
    
    let lines = source.components(separatedBy: .newlines).count
    print("   Lines: \(lines)")
    
    // Run the tokenizer and parser
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "cat '\(testFile.path)' | swift run PySwiftAST 2>&1"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if output.contains("✅ Parsed successfully") {
            print("   ✅ Parser succeeded")
            
            // Count tokens if available
            if let tokensMatch = output.range(of: #"(\d+) tokens"#, options: .regularExpression) {
                let tokensStr = output[tokensMatch]
                print("   \(tokensStr)")
            }
        } else if output.contains("⚠️") {
            print("   ⚠️  Partial parse (some features not fully supported)")
        } else {
            print("   ❌ Parser failed")
            // Print first error line
            let lines = output.components(separatedBy: .newlines)
            if let errorLine = lines.first(where: { $0.contains("Error") || $0.contains("error") }) {
                print("      \(errorLine.trimmingCharacters(in: .whitespaces))")
            }
        }
    } catch {
        print("   ❌ Execution failed: \(error)")
    }
    
    print()
}
