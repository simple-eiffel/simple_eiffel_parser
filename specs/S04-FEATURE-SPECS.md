# S04: FEATURE SPECIFICATIONS

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## EIFFEL_PARSER Features

### parse_string
**Signature:** `parse_string (a_source: STRING): EIFFEL_AST`
**Purpose:** Parse Eiffel source from string
**Process:**
1. Tokenize via EIFFEL_LEXER
2. Parse class declarations
3. Build AST with classes, features, parents
4. Collect errors for invalid syntax

### parse_file
**Signature:** `parse_file (a_path: STRING): EIFFEL_AST`
**Purpose:** Parse Eiffel source from file
**Process:**
1. Read file contents
2. Call parse_string

## EIFFEL_LEXER Features

### make
**Signature:** `make (a_source: STRING)`
**Purpose:** Create lexer for source string

### all_tokens
**Signature:** `all_tokens: ARRAYED_LIST [EIFFEL_TOKEN]`
**Purpose:** Tokenize entire source

### Token Types
- Keywords (class, feature, do, end, etc.)
- Identifiers
- Operators and symbols
- Literals (string, number, character)
- Comments

## EIFFEL_CLASS_NODE Features

### feature_by_name
**Signature:** `feature_by_name (a_name: STRING): detachable EIFFEL_FEATURE_NODE`
**Purpose:** Find feature by case-insensitive name lookup

### add_feature, add_parent, add_creator
**Purpose:** Build class structure during parsing

## DBC_ANALYZER Features

### analyze_file_content
**Signature:** `analyze_file_content (a_content, a_class_name, a_library_name, a_file_path: STRING)`
**Purpose:** Analyze single file for DbC metrics
**Metrics captured:**
- Feature count (excluding attributes)
- Features with require
- Features with ensure
- Classes with invariant
- Contract line counts

### total_score
**Signature:** `total_score: INTEGER`
**Purpose:** Calculate 0-100 DbC coverage score
**Formula:** Based on contract density per feature
