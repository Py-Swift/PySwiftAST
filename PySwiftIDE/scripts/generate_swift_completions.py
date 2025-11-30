#!/usr/bin/env python3.13
"""
Generate Swift code for MonacoAnalyzer completions from harvested Python docs.
"""

import json
import sys
from pathlib import Path

def format_swift_array_item(item: dict, is_constant: bool = False) -> str:
    """Format a single completion item as Swift code."""
    if is_constant:
        name = item['name']
        value = item.get('value', '')
        doc = item['doc']
        return f'.constant(name: "{name}", value: "{value}", documentation: "{doc}")'
    else:
        name = item['name']
        params = item.get('params', [])
        doc = item['doc']
        params_str = ', '.join(f'"{p}"' for p in params)
        return f'.function(name: "{name}", parameters: [{params_str}], documentation: "{doc}")'

def generate_builtin_functions(data: list) -> str:
    """Generate Swift code for built-in functions."""
    lines = ["    private static let builtinFunctions: [CompletionItem] = ["]
    
    for item in data:
        line = "        " + format_swift_array_item(item)
        lines.append(line + ",")
    
    lines.append("    ]")
    return '\n'.join(lines)

def generate_type_methods(type_name: str, methods: list) -> str:
    """Generate Swift code for a type's methods."""
    # Map Python type names to Swift struct names
    type_map = {
        'str': 'StringMethods',
        'list': 'ListMethods',
        'dict': 'DictMethods',
        'set': 'SetMethods',
        'frozenset': 'FrozensetMethods',
        'bytes': 'BytesMethods',
        'bytearray': 'BytearrayMethods',
        'tuple': 'TupleMethods',
    }
    
    struct_name = type_map.get(type_name, f'{type_name.capitalize()}Methods')
    
    lines = [
        f"    /// {type_name.capitalize()} type methods - for use when type inference determines an object is a {type_name}",
        f"    struct {struct_name} {{",
        "        static let methods: [CompletionItem] = ["
    ]
    
    for item in methods:
        line = "            " + format_swift_array_item(item)
        lines.append(line + ",")
    
    lines.append("        ]")
    lines.append("    }")
    
    return '\n'.join(lines)

def generate_math_module(data: list) -> str:
    """Generate Swift code for math module."""
    lines = ["    private static let mathModuleCompletions: [CompletionItem] = ["]
    
    # Separate constants and functions
    constants = [item for item in data if item.get('type') == 'constant']
    functions = [item for item in data if item.get('type') == 'function']
    
    # Add constants first
    if constants:
        lines.append("        // Math module constants")
    for item in constants:
        line = "        " + format_swift_array_item(item, is_constant=True)
        lines.append(line + ",")
    
    # Add functions
    if functions and constants:
        lines.append("")
        lines.append("        // Math module functions")
    for item in functions:
        line = "        " + format_swift_array_item(item)
        lines.append(line + ",")
    
    lines.append("    ]")
    return '\n'.join(lines)

def main():
    """Generate Swift code from harvested Python docs."""
    json_file = Path('/Volumes/CodeSSD/GitHub/PySwiftAST/PySwiftIDE/scripts/python_docs.json')
    output_file = Path('/Volumes/CodeSSD/GitHub/PySwiftAST/PySwiftIDE/scripts/generated_completions.swift')
    
    print("📖 Reading harvested Python documentation...")
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"✅ Loaded documentation from Python {data['python_version'].split()[0]}")
    
    # Generate Swift code sections
    print("\n🔧 Generating Swift code...")
    
    swift_code = []
    
    # Header
    swift_code.append("// MARK: - Generated Python Completions")
    swift_code.append("// Generated from Python 3.13 documentation using inspect.getdoc()")
    swift_code.append("// Generated on: " + __import__('datetime').datetime.now().isoformat())
    swift_code.append("")
    
    # Built-in functions
    print("   📚 Built-in functions...")
    swift_code.append("    // MARK: - Built-in Functions")
    swift_code.append(generate_builtin_functions(data['builtin_functions']))
    swift_code.append("")
    
    # Type methods
    print("   📝 Type methods...")
    type_order = ['str', 'list', 'dict', 'set', 'frozenset', 'bytes', 'bytearray', 'tuple']
    for type_name in type_order:
        if type_name in data['type_methods']:
            print(f"      - {type_name}: {len(data['type_methods'][type_name])} methods")
            swift_code.append("    // MARK: - " + type_name.capitalize() + " Methods")
            swift_code.append(generate_type_methods(type_name, data['type_methods'][type_name]))
            swift_code.append("")
    
    # Math module
    print("   🔢 Math module...")
    swift_code.append("    // MARK: - Math Module")
    swift_code.append(generate_math_module(data['math_module']))
    swift_code.append("")
    
    # Write output
    output_content = '\n'.join(swift_code)
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(output_content)
    
    print(f"\n✅ Swift code generated: {output_file}")
    print(f"   Total lines: {len(swift_code)}")
    print("\n💡 Next steps:")
    print("   1. Review the generated code in generated_completions.swift")
    print("   2. Copy relevant sections to MonacoAnalyzer.swift")
    print("   3. Run swift build to verify compilation")
    print("   4. Run swift test to ensure tests pass")

if __name__ == '__main__':
    main()
