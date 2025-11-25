import Foundation

// Inline UTF8Tokenizer test
let source = "x = 42"
print("Source: \(source)")

// Try creating tokenizer manually
let bytes = Array(source.utf8)
print("Bytes count: \(bytes.count)")
for (i, byte) in bytes.enumerated() {
    print("  [\(i)] 0x\(String(byte, radix: 16)) '\(Character(UnicodeScalar(byte)))'")
}
