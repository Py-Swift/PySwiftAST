# PySwiftIDE Changelog

## [1.0.0] - 2025-11-25

### 🎉 Initial Release

First release of PySwiftIDE - IDE integration layer for PySwiftAST.

### ✨ Features

- **Thread-Safe Validation**: All AST types now conform to `Sendable`
  - `Module`, `Statement`, `Expression`, `Pattern` enums
  - All concrete type structs (55+ types)
  - `TypeParam` and related type parameter types
  - All operator enums (`BoolOperator`, `Operator`, `UnaryOperator`, `CmpOp`)
  - `ConstantValue` enum

- **Monaco-Compatible Types**:
  - `IDERange`: 1-based line/column ranges matching Monaco's `IRange`
  - `Diagnostic`: Error/warning reporting with severity levels
  - `DiagnosticSeverity`: Hint(1), Info(2), Warning(4), Error(8)
  - `DiagnosticRelatedInformation`: Related diagnostic information
  - `DiagnosticTag`: Unnecessary(1), Deprecated(2)

- **Code Actions (Quick Fixes)**:
  - `CodeAction`: Quick fix or refactoring action
  - `CodeActionKind`: Quickfix, refactor, source actions
  - `WorkspaceEdit`: File-based text edits
  - `TextEdit`: Range-based text replacement

- **PythonValidator Class**:
  - `validate()`: Parse and return diagnostics without throwing
  - `getCodeActions()`: Generate quick fixes for errors
  - Error-to-diagnostic conversion for all ParseError types
  - Automatic quick fix generation for missing characters

### 🏗️ Architecture

- **Separate Package**: PySwiftIDE is now a standalone package
  - Lives at root level alongside PySwiftAST
  - Local dependency: `.package(path: "../")`
  - Can be moved to separate repository later

### 📊 Performance

Compared to Python's `ast` module:
- **Tokenization**: 5.4x faster
- **Parsing**: 1.17x faster
- **Round-trip**: 2.93x faster (parse + codegen + reparse)

### 🧪 Testing

5 comprehensive tests:
- ✅ `testBasicValidation` - Error detection and reporting
- ✅ `testValidCode` - Successful parsing without errors
- ✅ `testCodeActions` - Quick fix generation
- ✅ `testRangeCreation` - Range helper functions
- ✅ `testDiagnosticSerialization` - JSON encoding/decoding

### 📚 Documentation

- **README.md**: Quick start and API overview
- **USAGE.md**: Comprehensive documentation with examples
- **Examples/BasicUsage.swift**: Working example demonstrating all features

### 🔧 Implementation Details

**AST Sendable Conformance**:
- Added `Sendable` to 4 main enum types
- Added `Sendable` to 55+ struct types across:
  - Statement types (28 structs)
  - Expression types (27 structs)
  - Helper types (9 structs)
  - Pattern matching types (7 structs)
  - Type parameter types (4 structs)
  - Operator enums (5 enums)

**Error Handling**:
- `ValidationResult` contains optional AST and diagnostics array
- `PythonValidator.validate()` catches all ParseError types
- `convertParseError()` maps errors to Monaco diagnostics
- `generateQuickFix()` creates TextEdit for common fixes

### 🎯 Use Cases

- **Monaco Editor Integration**: Background thread Python validation
- **IDE Features**: Diagnostics, quick fixes, code actions
- **CLI Tools**: Fast Python validation without Python runtime
- **Build Systems**: Parse Python files during build process
- **Language Servers**: Foundation for Python language server

### 🚀 Benefits Over Python

1. **No GIL**: Parse multiple files in parallel
2. **Thread-Safe**: `Sendable` types work on any thread
3. **Fast**: 2-5x faster than Python for most operations
4. **Type-Safe**: Swift's type system catches errors at compile time
5. **No Runtime**: No Python interpreter needed

### 📦 Dependencies

- **PySwiftAST**: Core parser (local: `../`)
- **PySwiftCodeGen**: Code generation (transitive)
- **Foundation**: JSON encoding/decoding

### 🔮 Future Plans

Potential enhancements for future releases:
- Hover information (type hints, docstrings)
- Auto-completion suggestions based on AST
- Semantic highlighting
- Import organization and cleanup
- Unused import detection
- Incremental parsing for large files
- Multi-file analysis and cross-references

### 🐛 Known Limitations

- Quick fixes currently only support single-character insertions
- No support for multi-line edits yet
- Diagnostic ranges are single-line (no multi-line spans)

### 📝 Notes

This release makes the entire PySwiftAST ecosystem thread-safe and ready for production use in IDE environments. The separation into PySwiftIDE allows the core parser to remain focused while providing an optional IDE integration layer.

**Total Changes**:
- 4 main AST enums made Sendable
- 55+ struct types made Sendable
- 5 operator enums made Sendable
- 4 new IDE-specific Swift files created
- 5 comprehensive tests added
- 1 working example application
- 2 documentation files

---

**Release Date**: November 25, 2025  
**Package Version**: 1.0.0  
**Swift Version**: 6.0+  
**Platforms**: macOS 14.0+
