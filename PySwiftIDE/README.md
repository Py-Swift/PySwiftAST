# PySwiftIDE

IDE integration layer for PySwiftAST - provides Monaco Editor compatible diagnostics, code actions, and validation.

## Features

- 🎯 **Monaco-Compatible Types** - Complete language feature API matching Monaco Editor
- ⚡ **Fast Validation** - Parse Python on any thread without GIL
- 🔧 **Quick Fixes** - Auto-generate code actions for common errors
- 📍 **Precise Ranges** - Line and column information for accurate squigglies
- 🚀 **Native Performance** - 2.93x faster than Python for validation
- 🎨 **Full Language Support** - Hover, completion, symbols, formatting, and more

## Usage

```swift
import PySwiftIDE

let code = """
def func()
    pass
"""

let validator = PythonValidator(source: code)
let result = validator.validate()

// Get diagnostics for Monaco
for diagnostic in result.diagnostics {
    print("Error at line \(diagnostic.range.startLineNumber): \(diagnostic.message)")
    // Send to Monaco: monaco.editor.setModelMarkers(model, "python", [diagnostic])
}

// Get code actions (quick fixes)
let actions = validator.getCodeActions(for: diagnostic.range, diagnostics: result.diagnostics)
// Send to Monaco: monaco.languages.registerCodeActionProvider("python", ...)
```

## Monaco Integration

### Diagnostics (Error Markers)

```swift
let diagnostics = validator.validate().diagnostics
// Convert to JSON and send to Monaco
let jsonData = try JSONEncoder().encode(diagnostics)
// monaco.editor.setModelMarkers(model, "python", diagnostics)
```

### Code Actions (Quick Fixes)

```swift
let actions = validator.getCodeActions(for: range, diagnostics: diagnostics)
// monaco.languages.registerCodeActionProvider("python", {
//     provideCodeActions: () => actions
// })
```

## Types

All types are `Codable` and `Sendable` for easy JSON encoding and thread-safe usage.

### `Diagnostic`
- `severity`: `.error`, `.warning`, `.info`, `.hint`
- `message`: Human-readable error message
- `range`: `IDERange` with line and column positions
- `code`: Optional error code for categorization
- `source`: "PySwiftAST"

### `CodeAction`
- `title`: "Insert ':'"
- `kind`: `.quickfix`, `.refactor`, etc.
- `edit`: `WorkspaceEdit` with text changes
- `isPreferred`: Whether this is the primary fix

### `IDERange`
- `startLineNumber`, `startColumn` (1-based)
- `endLineNumber`, `endColumn` (1-based)
- Compatible with `monaco.IRange`

### Monaco Language Features

**Core Types** (for diagnostics and quick fixes):
- `Diagnostic`, `CodeAction`, `TextEdit`, `IDERange`

**Language Features** (full Monaco API):
- `Hover` - Hover information with markdown/code blocks
- `CompletionItem` / `CompletionList` - Auto-completion suggestions
- `DocumentSymbol` - Outline view and breadcrumb navigation
- `Location` / `LocationLink` - Go to definition support
- `SignatureHelp` - Function signature hints during typing
- `InlayHint` - Inline type and parameter name hints
- `FoldingRange` - Code folding for functions/classes/imports
- `FormattingOptions` - Code formatting configuration

All types are `Codable` and `Sendable` for JSON serialization and thread safety.

## Example: Monaco Language Provider

```typescript
// In your Monaco Editor setup
monaco.languages.registerCodeActionProvider('python', {
    provideCodeActions: async (model, range, context) => {
        // Call your Swift backend
        const response = await fetch('/api/python/codeActions', {
            method: 'POST',
            body: JSON.stringify({ 
                code: model.getValue(),
                range: range,
                diagnostics: context.markers
            })
        });
        
        return await response.json(); // Returns [CodeAction]
    }
});
```

## Dependencies

- **PySwiftAST** - Core Python parser
- **PySwiftCodeGen** - Code generation for validation

## License

MIT - Same as PySwiftAST
