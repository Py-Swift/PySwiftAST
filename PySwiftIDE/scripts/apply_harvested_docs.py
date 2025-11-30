#!/usr/bin/env python3.13
"""
Apply harvested Python documentation to MonacoAnalyzer.swift
"""

import json
import re
from pathlib import Path

def read_swift_file(file_path: Path) -> str:
    """Read the Swift file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return f.read()

def write_swift_file(file_path: Path, content: str):
    """Write the Swift file."""
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def replace_section(content: str, start_marker: str, end_marker: str, new_content: str) -> str:
    """Replace a section between two markers."""
    # Find the start
    start_idx = content.find(start_marker)
    if start_idx == -1:
        print(f"⚠️  Could not find start marker: {start_marker[:50]}...")
        return content
    
    # Find the end (search from start position)
    end_idx = content.find(end_marker, start_idx + len(start_marker))
    if end_idx == -1:
        print(f"⚠️  Could not find end marker: {end_marker[:50]}...")
        return content
    
    # Replace
    return content[:start_idx] + new_content + content[end_idx:]

def generate_builtin_functions(data: list) -> str:
    """Generate Swift code for built-in functions."""
    lines = ["    private static let builtinFunctions: [CompletionItem] = ["]
    
    for item in data:
        params = item.get('params', [])
        doc = item['doc']
        params_str = ', '.join(f'"{p}"' for p in params)
        # Fix newline in print function
        if item['name'] == 'print':
            params_str = params_str.replace("end='", "end='\\\\n").replace("'\"", "'\\n\"")
        line = f'        .function(name: "{item["name"]}", parameters: [{params_str}], documentation: "{doc}")'
        lines.append(line + ",")
    
    lines.append("    ]")
    return '\n'.join(lines)

def generate_type_methods_struct(type_name: str, methods: list) -> str:
    """Generate Swift code for a type's methods struct."""
    type_map = {
        'str': ('StringMethods', 'string'),
        'list': ('ListMethods', 'list'),
        'dict': ('DictMethods', 'dict'),
        'set': ('SetMethods', 'set'),
        'frozenset': ('FrozensetMethods', 'frozenset'),
        'bytes': ('BytesMethods', 'bytes'),
        'bytearray': ('BytearrayMethods', 'bytearray'),
        'tuple': ('TupleMethods', 'tuple'),
    }
    
    struct_name, type_desc = type_map.get(type_name, (f'{type_name.capitalize()}Methods', type_name))
    
    lines = [
        f"    /// {type_name.capitalize()} type methods - for use when type inference determines an object is a {type_desc}",
        f"    struct {struct_name} {{",
        "        static let methods: [CompletionItem] = ["
    ]
    
    for item in methods:
        params = item.get('params', [])
        doc = item['doc']
        params_str = ', '.join(f'"{p}"' for p in params)
        line = f'            .function(name: "{item["name"]}", parameters: [{params_str}], documentation: "{doc}")'
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
        name = item['name']
        value = item.get('value', '')
        doc = item['doc']
        line = f'        .constant(name: "{name}", value: "{value}", documentation: "{doc}")'
        lines.append(line + ",")
    
    # Add functions
    if functions and constants:
        lines.append("")
        lines.append("        // Math module functions")
    for item in functions:
        params = item.get('params', [])
        doc = item['doc']
        params_str = ', '.join(f'"{p}"' for p in params)
        line = f'        .function(name: "{item["name"]}", parameters: [{params_str}], documentation: "{doc}")'
        lines.append(line + ",")
    
    lines.append("    ]")
    return '\n'.join(lines)

def main():
    """Apply harvested documentation to MonacoAnalyzer.swift."""
    json_file = Path('/Volumes/CodeSSD/GitHub/PySwiftAST/PySwiftIDE/scripts/python_docs.json')
    swift_file = Path('/Volumes/CodeSSD/GitHub/PySwiftAST/PySwiftIDE/Sources/PySwiftIDE/MonacoAnalyzer.swift')
    
    print("📖 Reading files...")
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    content = read_swift_file(swift_file)
    original_content = content
    
    print(f"✅ Loaded documentation from Python {data['python_version'].split()[0]}")
    print(f"✅ Loaded MonacoAnalyzer.swift ({len(content)} bytes)")
    
    # 1. Replace builtinFunctions
    print("\n🔧 Replacing builtinFunctions...")
    new_builtins = generate_builtin_functions(data['builtin_functions'])
    content = replace_section(
        content,
        "    private static let builtinFunctions: [CompletionItem] = [",
        "    ]\n    \n    // MARK: - Built-in Type Method Definitions",
        new_builtins + "\n    \n    // MARK: - Built-in Type Method Definitions"
    )
    
    # 2. Replace type method structs
    type_order = ['str', 'list', 'dict', 'set', 'bytes', 'bytearray', 'tuple']
    
    for type_name in type_order:
        if type_name not in data['type_methods']:
            continue
        
        print(f"🔧 Replacing {type_name} methods...")
        methods = data['type_methods'][type_name]
        new_struct = generate_type_methods_struct(type_name, methods)
        
        # Find the struct
        struct_pattern = f"struct ({'String' if type_name == 'str' else type_name.capitalize() if type_name in ['list', 'dict', 'set', 'tuple'] else type_name.capitalize() + 's' if type_name == 'bytes' else type_name.capitalize()})Methods"
        if type_name == 'bytearray':
            struct_pattern = "struct BytearrayMethods"
        
        # Find start of struct
        struct_regex = re.compile(
            r'(    /// .+ type methods.+\n    struct ' + struct_pattern.split()[-1] + r' \{.+?\n        \]\n    \})',
            re.DOTALL
        )
        
        match = struct_regex.search(content)
        if match:
            content = content.replace(match.group(1), new_struct)
            print(f"   ✅ Replaced {type_name} methods")
        else:
            print(f"   ⚠️  Could not find {struct_pattern}")
    
    # 3. Replace math module completions
    print("🔧 Replacing math module completions...")
    new_math = generate_math_module(data['math_module'])
    content = replace_section(
        content,
        "    private static let mathModuleCompletions: [CompletionItem] = [",
        "    ]\n    \n    // MARK: - Sequence Operations",
        new_math + "\n    \n    // MARK: - Sequence Operations"
    )
    
    # Write the updated file
    if content != original_content:
        write_swift_file(swift_file, content)
        print(f"\n✅ Successfully updated MonacoAnalyzer.swift")
        print(f"   Original size: {len(original_content)} bytes")
        print(f"   New size: {len(content)} bytes")
        print(f"   Difference: {len(content) - len(original_content):+d} bytes")
    else:
        print("\n⚠️  No changes were made to the file")
    
    print("\n💡 Next steps:")
    print("   1. Run swift build to verify compilation")
    print("   2. Run swift test to ensure tests pass")

if __name__ == '__main__':
    main()
