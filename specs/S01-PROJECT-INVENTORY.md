# S01: PROJECT INVENTORY

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Project Structure

```
simple_eiffel_parser/
├── src/
│   ├── eiffel_parser.e        # Native recursive descent parser
│   ├── eiffel_lexer.e         # Tokenizer
│   ├── eiffel_token.e         # Token class
│   ├── simple_eiffel_parser.e # Gobo bridge facade
│   ├── gobo_parser_bridge.e   # Gobo ET_PARSER wrapper
│   ├── eiffel_ast.e           # AST root
│   ├── eiffel_class_node.e    # Class AST node
│   ├── eiffel_feature_node.e  # Feature AST node
│   ├── eiffel_parent_node.e   # Parent AST node
│   ├── eiffel_argument_node.e # Argument AST node
│   ├── eiffel_local_node.e    # Local variable node
│   ├── eiffel_parse_error.e   # Parse error
│   ├── dbc_analyzer.e         # DbC metrics analyzer
│   └── dbc_class_metrics.e    # Per-class metrics
├── testing/
│   ├── test_app.e             # Test entry
│   └── lib_tests.e            # Unit tests
├── research/                   # 7S documents
├── specs/                      # Specifications
├── simple_eiffel_parser.ecf   # Library ECF
└── README.md
```

## File Inventory

| File | Type | Lines | Purpose |
|------|------|-------|---------|
| eiffel_parser.e | Source | ~965 | Native parser |
| eiffel_lexer.e | Source | ~450 | Tokenizer |
| eiffel_token.e | Source | ~200 | Token representation |
| simple_eiffel_parser.e | Source | ~145 | Gobo facade |
| eiffel_ast.e | Source | ~65 | AST root |
| eiffel_class_node.e | Source | ~155 | Class node |
| eiffel_feature_node.e | Source | ~200 | Feature node |
| dbc_analyzer.e | Source | ~335 | Contract analyzer |

## Dependencies

### Optional: Gobo Libraries
- ET_EIFFEL_PARSER (for SIMPLE_EIFFEL_PARSER)

### Eiffel Base Libraries
- ARRAYED_LIST, HASH_TABLE, STRING
- PLAIN_TEXT_FILE
