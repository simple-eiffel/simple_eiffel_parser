# 7S-01: SCOPE


**Date**: 2026-01-23

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Problem Domain

Eiffel source code analysis requires parsing to extract:
- Class structure (name, inheritance, features)
- Design by Contract elements (require, ensure, invariant)
- Feature signatures and types
- Code metrics and analysis

Use cases include:
- IDE/editor support (LSP)
- Documentation generation
- Code quality analysis
- Refactoring tools
- DbC coverage metrics

## Target Users

1. **Tool Developers** - Building Eiffel development tools
2. **IDE Developers** - Creating editor plugins
3. **Documentation Generators** - Extracting API documentation
4. **Code Analyzers** - Computing metrics, finding issues

## Boundaries

### In Scope
- Eiffel source code lexing (tokenization)
- Eiffel source code parsing
- AST (Abstract Syntax Tree) generation
- Class structure extraction
- Feature extraction (procedures, functions, attributes)
- Contract extraction (require, ensure)
- Inheritance parsing
- Creation procedure parsing
- Gobo parser bridge for advanced use

### Out of Scope
- Full semantic analysis
- Type checking
- Code generation
- Compilation
- Multi-file project analysis
- ECF parsing

## Key Capabilities

1. **Multiple parsers:**
   - EIFFEL_PARSER - Native recursive descent
   - SIMPLE_EIFFEL_PARSER - Gobo bridge facade
   - DBC_ANALYZER - Contract metrics

2. **AST nodes:**
   - EIFFEL_AST, EIFFEL_CLASS_NODE, EIFFEL_FEATURE_NODE
   - Parent, argument, local representations
