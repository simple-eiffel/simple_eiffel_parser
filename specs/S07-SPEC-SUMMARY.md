# S07: SPECIFICATION SUMMARY

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Library Summary

**Purpose:** Eiffel source code parsing for structure extraction, IDE support, and DbC analysis.

**Core Functionality:**
1. Eiffel source tokenization (lexer)
2. Recursive descent parsing
3. AST generation with typed nodes
4. Contract extraction (require/ensure/invariant)
5. DbC coverage analysis and scoring

## API Surface

### Parsers

| Parser | Purpose | Backend |
|--------|---------|---------|
| EIFFEL_PARSER | Full native parsing | Built-in |
| SIMPLE_EIFFEL_PARSER | Gobo bridge | Gobo ET_PARSER |

### AST Nodes

| Node | Represents |
|------|------------|
| EIFFEL_AST | Root container |
| EIFFEL_CLASS_NODE | Class declaration |
| EIFFEL_FEATURE_NODE | Feature declaration |
| EIFFEL_PARENT_NODE | Inheritance reference |
| EIFFEL_ARGUMENT_NODE | Feature argument |
| EIFFEL_LOCAL_NODE | Local variable |
| EIFFEL_PARSE_ERROR | Syntax error |

### Analysis

| Class | Purpose |
|-------|---------|
| DBC_ANALYZER | Contract metrics |
| DBC_CLASS_METRICS | Per-class results |

## Quality Metrics

| Metric | Value |
|--------|-------|
| Classes | 14+ |
| Total Lines | ~3085 |
| Invariants | 15+ |

## Key Design Decisions

1. **Dual backend** - Native and Gobo options
2. **Typed AST** - Separate node classes
3. **Error recovery** - Partial parsing on errors
4. **DbC focus** - Contract analysis built-in
