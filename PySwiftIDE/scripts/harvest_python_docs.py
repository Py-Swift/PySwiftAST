#!/usr/bin/env python3.13
"""
Harvest Python documentation for IDE completions.

This script extracts docstrings from Python 3.13's built-in types and functions
using the inspect module, then generates Swift code for MonacoAnalyzer completions.
"""

import inspect
import sys
import math
import builtins
from typing import List, Tuple, Optional
import json

def clean_docstring(doc: Optional[str]) -> str:
    """Clean and format a docstring for Swift string literal."""
    if not doc:
        return ""
    
    # Get first paragraph or first few lines
    lines = doc.strip().split('\n')
    
    # Remove empty lines at start
    while lines and not lines[0].strip():
        lines.pop(0)
    
    # Take first paragraph (stop at first empty line or after reasonable length)
    result_lines = []
    for line in lines:
        stripped = line.strip()
        if not stripped and result_lines:
            break  # End of first paragraph
        if stripped:
            result_lines.append(stripped)
        if len(' '.join(result_lines)) > 300:  # Keep it reasonable
            break
    
    doc_text = ' '.join(result_lines)
    
    # Escape special characters for Swift string
    doc_text = doc_text.replace('\\', '\\\\')
    doc_text = doc_text.replace('"', '\\"')
    doc_text = doc_text.replace('\n', ' ')
    doc_text = doc_text.replace('\r', ' ')
    
    # Normalize whitespace
    doc_text = ' '.join(doc_text.split())
    
    return doc_text

def get_function_signature(func) -> Tuple[str, List[str]]:
    """Extract function name and parameters."""
    try:
        sig = inspect.signature(func)
        params = []
        for param_name, param in sig.parameters.items():
            if param_name == 'self':
                continue
            
            param_str = param_name
            
            # Add default value if present
            if param.default != inspect.Parameter.empty:
                default_val = param.default
                if isinstance(default_val, str):
                    param_str = f"{param_name}='{default_val}'"
                elif default_val is None:
                    param_str = f"{param_name}=None"
                else:
                    param_str = f"{param_name}={default_val}"
            elif param.kind == inspect.Parameter.VAR_POSITIONAL:
                param_str = f"*{param_name}"
            elif param.kind == inspect.Parameter.VAR_KEYWORD:
                param_str = f"**{param_name}"
            
            params.append(param_str)
        
        return func.__name__, params
    except (ValueError, TypeError):
        # Fallback for built-in functions without signature
        return func.__name__, []

def harvest_builtin_functions() -> List[dict]:
    """Harvest docstrings from built-in functions."""
    functions = []
    
    # Key built-in functions to document
    builtin_names = [
        'abs', 'all', 'any', 'ascii', 'bin', 'bool', 'breakpoint', 'bytearray',
        'bytes', 'callable', 'chr', 'classmethod', 'compile', 'complex',
        'delattr', 'dict', 'dir', 'divmod', 'enumerate', 'eval', 'exec',
        'filter', 'float', 'format', 'frozenset', 'getattr', 'globals',
        'hasattr', 'hash', 'help', 'hex', 'id', 'input', 'int', 'isinstance',
        'issubclass', 'iter', 'len', 'list', 'locals', 'map', 'max',
        'memoryview', 'min', 'next', 'object', 'oct', 'open', 'ord', 'pow',
        'print', 'property', 'range', 'repr', 'reversed', 'round', 'set',
        'setattr', 'slice', 'sorted', 'staticmethod', 'str', 'sum', 'super',
        'tuple', 'type', 'vars', 'zip'
    ]
    
    for name in builtin_names:
        if hasattr(builtins, name):
            func = getattr(builtins, name)
            doc = clean_docstring(inspect.getdoc(func))
            try:
                func_name, params = get_function_signature(func)
            except:
                func_name = name
                params = []
            
            functions.append({
                'name': func_name,
                'params': params,
                'doc': doc
            })
    
    return functions

def harvest_type_methods(type_obj, type_name: str) -> List[dict]:
    """Harvest docstrings from a type's methods."""
    methods = []
    
    # Get all methods (excluding private ones starting with _)
    for name in dir(type_obj):
        if name.startswith('_'):
            continue
        
        try:
            attr = getattr(type_obj, name)
            if callable(attr):
                doc = clean_docstring(inspect.getdoc(attr))
                try:
                    _, params = get_function_signature(attr)
                except:
                    params = []
                
                methods.append({
                    'name': name,
                    'params': params,
                    'doc': doc
                })
        except AttributeError:
            pass
    
    return methods

def harvest_math_module() -> List[dict]:
    """Harvest docstrings from math module."""
    items = []
    
    for name in dir(math):
        if name.startswith('_'):
            continue
        
        attr = getattr(math, name)
        doc = clean_docstring(inspect.getdoc(attr))
        
        if callable(attr):
            try:
                _, params = get_function_signature(attr)
            except:
                params = []
            
            items.append({
                'type': 'function',
                'name': f'math.{name}',
                'params': params,
                'doc': doc
            })
        else:
            # It's a constant
            items.append({
                'type': 'constant',
                'name': f'math.{name}',
                'value': str(attr),
                'doc': doc
            })
    
    return items

def generate_swift_completion_array(items: List[dict], indent: int = 12) -> str:
    """Generate Swift code for CompletionItem array."""
    indent_str = ' ' * indent
    lines = []
    
    for item in items:
        if 'value' in item:
            # Constant
            params_str = ', '.join(f'"{p}"' for p in item.get('params', []))
            line = f'{indent_str}.constant(name: "{item["name"]}", value: "{item["value"]}", documentation: "{item["doc"]}"),'
        else:
            # Function
            params_str = ', '.join(f'"{p}"' for p in item.get('params', []))
            line = f'{indent_str}.function(name: "{item["name"]}", parameters: [{params_str}], documentation: "{item["doc"]}"),'
        
        lines.append(line)
    
    return '\n'.join(lines)

def main():
    """Main harvesting function."""
    print("🌾 Harvesting Python 3.13 documentation...")
    print(f"Python version: {sys.version}")
    
    # Harvest built-in functions
    print("\n📚 Harvesting built-in functions...")
    builtin_functions = harvest_builtin_functions()
    print(f"   Found {len(builtin_functions)} built-in functions")
    
    # Harvest type methods
    print("\n📝 Harvesting type methods...")
    type_data = {
        'str': harvest_type_methods(str, 'str'),
        'list': harvest_type_methods(list, 'list'),
        'dict': harvest_type_methods(dict, 'dict'),
        'set': harvest_type_methods(set, 'set'),
        'frozenset': harvest_type_methods(frozenset, 'frozenset'),
        'bytes': harvest_type_methods(bytes, 'bytes'),
        'bytearray': harvest_type_methods(bytearray, 'bytearray'),
        'tuple': harvest_type_methods(tuple, 'tuple'),
    }
    
    for type_name, methods in type_data.items():
        print(f"   {type_name}: {len(methods)} methods")
    
    # Harvest math module
    print("\n🔢 Harvesting math module...")
    math_items = harvest_math_module()
    print(f"   Found {len(math_items)} math items")
    
    # Save to JSON file
    output_data = {
        'python_version': sys.version,
        'builtin_functions': builtin_functions,
        'type_methods': type_data,
        'math_module': math_items
    }
    
    output_file = '/Volumes/CodeSSD/GitHub/PySwiftAST/PySwiftIDE/scripts/python_docs.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Documentation harvested and saved to: {output_file}")
    
    # Generate sample Swift code
    print("\n🔧 Generating sample Swift code...")
    print("\n// Sample: Built-in Functions (first 5)")
    print("private static let builtinFunctions: [CompletionItem] = [")
    print(generate_swift_completion_array(builtin_functions[:5]))
    print("    // ... more functions")
    print("]")
    
    print("\n// Sample: String Methods (first 5)")
    print("struct StringMethods {")
    print("    static let methods: [CompletionItem] = [")
    print(generate_swift_completion_array(type_data['str'][:5]))
    print("        // ... more methods")
    print("    ]")
    print("}")
    
    print("\n✨ Done! Use the JSON file to update MonacoAnalyzer.swift")

if __name__ == '__main__':
    main()
