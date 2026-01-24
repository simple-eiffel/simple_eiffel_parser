# S06: BOUNDARIES

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## System Boundaries

### Parser Architecture

```
EIFFEL_PARSER (native)          SIMPLE_EIFFEL_PARSER (facade)
      |                                   |
      v                                   v
EIFFEL_LEXER                    GOBO_PARSER_BRIDGE
      |                                   |
      v                                   v
EIFFEL_TOKEN                    Gobo ET_EIFFEL_PARSER
      |                                   |
      +---------------+-----------------+
                      |
                      v
                  EIFFEL_AST
                      |
       +--------------+--------------+
       |              |              |
       v              v              v
EIFFEL_CLASS_NODE  EIFFEL_FEATURE_NODE  EIFFEL_PARSE_ERROR
       |
       +-- EIFFEL_PARENT_NODE
       +-- EIFFEL_ARGUMENT_NODE
       +-- EIFFEL_LOCAL_NODE
```

### Analysis Layer

```
DBC_ANALYZER
      |
      +-- uses EIFFEL_PARSER
      |
      v
DBC_CLASS_METRICS (per class results)
```

## Class Responsibilities

### EIFFEL_PARSER
- Tokenization via EIFFEL_LEXER
- Recursive descent parsing
- AST construction
- Error collection

### EIFFEL_LEXER
- Character-by-character scanning
- Token classification
- String/comment handling

### AST Nodes
- Data storage for parsed elements
- Access and query methods
- Structure representation

### DBC_ANALYZER
- File content analysis
- Contract counting
- Score calculation
- Color mapping for heatmaps

## Not Responsible For

- Semantic analysis
- Type checking
- Multi-file projects
- ECF parsing
- Code execution
- Compilation
