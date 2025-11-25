import Foundation

// Read file
let source = try String(contentsOfFile: "tests/ml_pipeline.py")
print("File size: \(source.count) characters")
print("Lines: \(source.components(separatedBy: "\n").count)")

// Create byte array
let bytes = Array(source.utf8)
print("UTF-8 bytes: \(bytes.count)")

// Test conversion speed
var times: [Double] = []
for _ in 0..<100 {
    let start = DispatchTime.now()
    let _ = Array(source.utf8)
    let end = DispatchTime.now()
    times.append(Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0)
}
times.sort()
print("UTF-8 conversion median: \(String(format: "%.3f", times[times.count / 2]))ms")
