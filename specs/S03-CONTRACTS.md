# S03: CONTRACTS

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Class Invariants

### EIFFEL_PARSER

```eiffel
invariant
    lexer_exists: lexer /= Void
    tokens_exist: tokens /= Void
    ast_exists: last_ast /= Void
```

### EIFFEL_AST

```eiffel
invariant
    classes_exist: classes /= Void
    errors_exist: parse_errors /= Void
```

### EIFFEL_CLASS_NODE

```eiffel
invariant
    name_not_empty: name /= Void and then not name.is_empty
    line_valid: line >= 1
    column_valid: column >= 1
    features_exist: features /= Void
    parents_exist: parents /= Void
    creators_exist: creators /= Void
```

### EIFFEL_FEATURE_NODE

```eiffel
invariant
    name_not_empty: name /= Void and then not name.is_empty
    line_valid: line >= 1
    column_valid: column >= 1
    arguments_exist: arguments /= Void
    locals_exist: locals /= Void
    kind_valid: kind >= Kind_procedure and kind <= Kind_external
```

### DBC_ANALYZER

```eiffel
invariant
    parser_created: parser /= Void
```

## Feature Contracts

### parse_string (EIFFEL_PARSER)

```eiffel
require
    source_not_void: a_source /= Void
ensure
    result_not_void: Result /= Void
```

### parse_file (EIFFEL_PARSER)

```eiffel
require
    path_not_empty: a_path /= Void and then not a_path.is_empty
ensure
    result_not_void: Result /= Void
```

### add_class (EIFFEL_AST)

```eiffel
require
    class_not_void: a_class /= Void
ensure
    class_added: classes.has (a_class)
```
