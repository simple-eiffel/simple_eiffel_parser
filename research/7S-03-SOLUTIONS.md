# 7S-03: SOLUTIONS

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Existing Solutions Comparison

### Eiffel Parsing Solutions

| Solution | Type | Features | Complexity |
|----------|------|----------|------------|
| Gobo ET_EIFFEL_PARSER | Full parser | Complete, industrial | Very High |
| EiffelStudio compiler | Full compiler | Complete | Very High |
| **simple_eiffel_parser** | **Lightweight** | **Structure extraction** | **Medium** |

### Design Approaches

**1. Full Grammar Parser (Gobo)**
- Complete ECMA-367 grammar
- Full semantic analysis capability
- Complex, many classes

**2. Lightweight Parser (simple_eiffel_parser)**
- Focus on structure extraction
- Tolerant of some syntax errors
- Simpler, focused on common needs

**3. Regex-Based**
- Very limited
- Breaks on complex code
- Not suitable for real use

### Why Both Approaches?

simple_eiffel_parser provides:

1. **EIFFEL_PARSER** - Native implementation
   - Fast startup
   - No Gobo dependency
   - Good for simple analysis

2. **SIMPLE_EIFFEL_PARSER** (Gobo bridge)
   - Full grammar support
   - Better error messages
   - Complex code handling

### Unique Features

1. **DbC Analysis** - DBC_ANALYZER for contract metrics
2. **Lenient Mode** - Recovers from parse errors
3. **Dual Backend** - Native or Gobo
4. **LSP Focus** - Designed for editor integration
