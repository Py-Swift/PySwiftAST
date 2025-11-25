import Foundation
import PySwiftAST

// Test UTF8Tokenizer directly
let source = "x = 42"
print("Testing UTF8Tokenizer with: '\(source)'")

do {
    let tokenizer = UTF8Tokenizer(source: source)
    print("Tokenizer created successfully")
    
    let tokens = try tokenizer.tokenize()
    print("Tokenization successful: \(tokens.count) tokens")
    
    for (i, token) in tokens.enumerated() {
        print("  [\(i)] \(token.type) '\(token.value)'")
    }
} catch {
    print("Error: \(error)")
}
