#!/usr/bin/env swift

import Foundation

// Simple profiling script to measure performance of different operations
// Run with: swift scripts/profile.swift

struct ProfileResult {
    let name: String
    let duration: TimeInterval
    let iterations: Int
    
    var avgMs: Double {
        (duration * 1000.0) / Double(iterations)
    }
}

func measure(_ name: String, iterations: Int = 1000, block: () throws -> Void) -> ProfileResult {
    // Warmup
    for _ in 0..<10 {
        try? block()
    }
    
    let start = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
        try? block()
    }
    let duration = CFAbsoluteTimeGetCurrent() - start
    
    return ProfileResult(name: name, duration: duration, iterations: iterations)
}

// Test string scanning patterns
func profileStringScanning() {
    print("=" * 60)
    print("STRING SCANNING PATTERNS")
    print("=" * 60)
    
    let testString = "abcdefghijklmnopqrstuvwxyz0123456789" * 100
    
    // Pattern 1: Character array indexing (current approach)
    let result1 = measure("Character array [Int]", iterations: 10000) {
        let chars = Array(testString)
        var pos = 0
        while pos < chars.count {
            _ = chars[pos]
            pos += 1
        }
    }
    
    // Pattern 2: String.Index (old approach)
    let result2 = measure("String.Index", iterations: 10000) {
        var index = testString.startIndex
        while index < testString.endIndex {
            _ = testString[index]
            index = testString.index(after: index)
        }
    }
    
    // Pattern 3: Substring slicing
    let result3 = measure("Substring slicing", iterations: 10000) {
        var substring = testString[...]
        while !substring.isEmpty {
            _ = substring.first
            substring = substring.dropFirst()
        }
    }
    
    // Pattern 4: UTF8 view
    let result4 = measure("UTF8 view", iterations: 10000) {
        let utf8 = Array(testString.utf8)
        var pos = 0
        while pos < utf8.count {
            _ = utf8[pos]
            pos += 1
        }
    }
    
    print("Results:")
    print("  \(result1.name): \(String(format: "%.3f", result1.avgMs)) ms avg")
    print("  \(result2.name): \(String(format: "%.3f", result2.avgMs)) ms avg")
    print("  \(result3.name): \(String(format: "%.3f", result3.avgMs)) ms avg")
    print("  \(result4.name): \(String(format: "%.3f", result4.avgMs)) ms avg")
    print()
}

// Test number parsing patterns
func profileNumberParsing() {
    print("=" * 60)
    print("NUMBER PARSING PATTERNS")
    print("=" * 60)
    
    let numbers = ["123", "456.789", "1e10", "0xFF", "0o77", "0b1010"]
    
    // Pattern 1: String-based parsing (current)
    let result1 = measure("String -> Double", iterations: 10000) {
        for num in numbers {
            _ = Double(num)
        }
    }
    
    // Pattern 2: Character accumulation
    let result2 = measure("Character accumulation", iterations: 10000) {
        for num in numbers {
            var result = 0.0
            var decimal = false
            var divisor = 1.0
            for char in num {
                if char == "." {
                    decimal = true
                    continue
                }
                if let digit = char.wholeNumberValue {
                    if decimal {
                        divisor *= 10
                        result += Double(digit) / divisor
                    } else {
                        result = result * 10 + Double(digit)
                    }
                }
            }
        }
    }
    
    print("Results:")
    print("  \(result1.name): \(String(format: "%.3f", result1.avgMs)) ms avg")
    print("  \(result2.name): \(String(format: "%.3f", result2.avgMs)) ms avg")
    print()
}

// Test token array growth patterns
func profileArrayGrowth() {
    print("=" * 60)
    print("ARRAY GROWTH PATTERNS")
    print("=" * 60)
    
    let itemCount = 10000
    
    // Pattern 1: Pre-allocated with reserveCapacity
    let result1 = measure("reserveCapacity", iterations: 1000) {
        var array: [Int] = []
        array.reserveCapacity(itemCount)
        for i in 0..<itemCount {
            array.append(i)
        }
    }
    
    // Pattern 2: No pre-allocation
    let result2 = measure("No pre-allocation", iterations: 1000) {
        var array: [Int] = []
        for i in 0..<itemCount {
            array.append(i)
        }
    }
    
    // Pattern 3: Pre-sized array
    let result3 = measure("Pre-sized array", iterations: 1000) {
        var array = Array(repeating: 0, count: itemCount)
        for i in 0..<itemCount {
            array[i] = i
        }
    }
    
    print("Results:")
    print("  \(result1.name): \(String(format: "%.3f", result1.avgMs)) ms avg")
    print("  \(result2.name): \(String(format: "%.3f", result2.avgMs)) ms avg")
    print("  \(result3.name): \(String(format: "%.3f", result3.avgMs)) ms avg")
    print()
}

// Test string building patterns
func profileStringBuilding() {
    print("=" * 60)
    print("STRING BUILDING PATTERNS")
    print("=" * 60)
    
    let parts = Array(repeating: "test", count: 1000)
    
    // Pattern 1: String concatenation
    let result1 = measure("String concatenation", iterations: 100) {
        var result = ""
        for part in parts {
            result += part
        }
    }
    
    // Pattern 2: Array join
    let result2 = measure("Array join", iterations: 100) {
        _ = parts.joined()
    }
    
    // Pattern 3: StringBuilder pattern
    let result3 = measure("Array + joined()", iterations: 100) {
        var builder: [String] = []
        builder.reserveCapacity(parts.count)
        for part in parts {
            builder.append(part)
        }
        _ = builder.joined()
    }
    
    print("Results:")
    print("  \(result1.name): \(String(format: "%.3f", result1.avgMs)) ms avg")
    print("  \(result2.name): \(String(format: "%.3f", result2.avgMs)) ms avg")
    print("  \(result3.name): \(String(format: "%.3f", result3.avgMs)) ms avg")
    print()
}

// Test character classification
func profileCharacterClassification() {
    print("=" * 60)
    print("CHARACTER CLASSIFICATION")
    print("=" * 60)
    
    let testChars: [Character] = Array("ABCabc123!@# \t\n")
    
    // Pattern 1: isLetter property
    let result1 = measure("char.isLetter", iterations: 100000) {
        for char in testChars {
            _ = char.isLetter
        }
    }
    
    // Pattern 2: Character ranges
    let result2 = measure("Character ranges", iterations: 100000) {
        for char in testChars {
            _ = (char >= "a" && char <= "z") || (char >= "A" && char <= "Z")
        }
    }
    
    // Pattern 3: Unicode scalar check
    let result3 = measure("Unicode scalars", iterations: 100000) {
        for char in testChars {
            if let scalar = char.unicodeScalars.first {
                _ = (scalar.value >= 65 && scalar.value <= 90) || 
                    (scalar.value >= 97 && scalar.value <= 122)
            }
        }
    }
    
    print("Results:")
    print("  \(result1.name): \(String(format: "%.3f", result1.avgMs)) ms avg")
    print("  \(result2.name): \(String(format: "%.3f", result2.avgMs)) ms avg")
    print("  \(result3.name): \(String(format: "%.3f", result3.avgMs)) ms avg")
    print()
}

// Helper for string repetition
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// Run all profiles
print("\n")
print("╔════════════════════════════════════════════════════════════╗")
print("║           PySwiftAST PERFORMANCE PROFILING                 ║")
print("╔════════════════════════════════════════════════════════════╗")
print("\n")

profileStringScanning()
profileNumberParsing()
profileArrayGrowth()
profileStringBuilding()
profileCharacterClassification()

print("=" * 60)
print("PROFILING COMPLETE")
print("=" * 60)
print("\nRecommendations will be based on results above.")
print("Run with: swift scripts/profile.swift")
print()
