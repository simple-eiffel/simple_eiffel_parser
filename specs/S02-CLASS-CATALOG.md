# S02: CLASS CATALOG

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Class Overview

| Class | Purpose | LOC |
|-------|---------|-----|
| EIFFEL_PARSER | Native recursive descent parser | ~965 |
| EIFFEL_LEXER | Source tokenization | ~450 |
| EIFFEL_TOKEN | Token representation | ~200 |
| SIMPLE_EIFFEL_PARSER | Gobo parser facade | ~145 |
| GOBO_PARSER_BRIDGE | Gobo ET_PARSER wrapper | ~200 |
| EIFFEL_AST | AST root container | ~65 |
| EIFFEL_CLASS_NODE | Class representation | ~155 |
| EIFFEL_FEATURE_NODE | Feature representation | ~200 |
| EIFFEL_PARENT_NODE | Parent class reference | ~100 |
| EIFFEL_ARGUMENT_NODE | Feature argument | ~40 |
| EIFFEL_LOCAL_NODE | Local variable | ~40 |
| EIFFEL_PARSE_ERROR | Parse error info | ~40 |
| DBC_ANALYZER | Contract metrics | ~335 |
| DBC_CLASS_METRICS | Per-class metrics | ~150 |

## EIFFEL_PARSER

### Features
**Parsing:** parse_string, parse_file
**Access:** last_ast

### Internal Structure
- Token-based recursive descent
- Separate parsing for class, feature, inherit, create clauses
- Skip helpers for error recovery

## EIFFEL_CLASS_NODE

### Attributes
name, line, column, is_deferred, is_expanded, is_frozen, header_comment, features, parents, creators

### Operations
add_feature, add_parent, add_creator, feature_by_name

## EIFFEL_FEATURE_NODE

### Attributes
name, line, column, kind, return_type, arguments, locals, precondition, postcondition, is_deferred, is_frozen, export_status

### Kind Constants
Kind_procedure, Kind_function, Kind_attribute, Kind_once_procedure, Kind_once_function, Kind_external

## DBC_ANALYZER

### Analysis Features
analyze_file_content, reset, color_for_score

### Metrics
total_features, total_with_require, total_with_ensure, total_with_invariant, total_score
