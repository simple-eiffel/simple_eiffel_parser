# 7S-06: SIZING


**Date**: 2026-01-23

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Implementation Size Analysis

### Actual Implementation

| Component | Lines | Classes |
|-----------|-------|---------|
| EIFFEL_PARSER | ~965 | 1 |
| EIFFEL_LEXER | ~450 | 1 |
| EIFFEL_TOKEN | ~200 | 1 |
| SIMPLE_EIFFEL_PARSER | ~145 | 1 |
| GOBO_PARSER_BRIDGE | ~200 | 1 |
| EIFFEL_AST | ~65 | 1 |
| EIFFEL_CLASS_NODE | ~155 | 1 |
| EIFFEL_FEATURE_NODE | ~200 | 1 |
| EIFFEL_PARENT_NODE | ~100 | 1 |
| EIFFEL_ARGUMENT_NODE | ~40 | 1 |
| EIFFEL_LOCAL_NODE | ~40 | 1 |
| EIFFEL_PARSE_ERROR | ~40 | 1 |
| DBC_ANALYZER | ~335 | 1 |
| DBC_CLASS_METRICS | ~150 | 1 |
| Test classes | ~200 | 3 |
| **Total** | **~3285** | **17** |

### Complexity Assessment

**Medium-High Complexity**
- Multiple parser implementations
- Full lexer
- AST node hierarchy
- DbC analysis

### Code Breakdown (EIFFEL_PARSER)

| Feature Group | Approximate Lines |
|---------------|-------------------|
| Initialization | 20 |
| Class parsing | 150 |
| Inherit parsing | 120 |
| Feature parsing | 250 |
| Type parsing | 80 |
| Skip helpers | 200 |
| Token access | 80 |
| Error handling | 65 |

### Performance

- Lexing: O(n) in source length
- Parsing: O(n) in token count
- Memory: O(classes * features * avg_size)
