# 7S-02: STANDARDS

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Applicable Standards

### Primary Standard

**Eiffel: Analysis, Design and Programming Language (ECMA-367)**
- Edition: 2nd (2006)
- URL: https://www.ecma-international.org/publications-and-standards/standards/ecma-367/
- Status: International standard

### Key Language Constructs Parsed

**Class Structure:**
```eiffel
[note]
[indexing]
[deferred | expanded | frozen] class CLASS_NAME [G, ...]
[obsolete "..."]
[inherit ...]
[create ...]
[convert ...]
feature {EXPORT} -- Comment
    feature_declarations
[invariant ...]
end
```

**Feature Structure:**
```eiffel
[frozen] feature_name [alias "..."] [(arguments)]: TYPE
    [assign setter_name]
    [note ...]
    [obsolete "..."]
    [require [else] ...]
    [local ...]
    do | once | deferred | external
    [rescue ...]
    [ensure [then] ...]
end
```

### Token Categories

| Category | Examples |
|----------|----------|
| Keywords | class, feature, do, end, require, ensure |
| Identifiers | Class names, feature names |
| Operators | +, -, *, /, /=, ~ |
| Symbols | :, ;, (, ), [, ], {, } |
| Literals | Numbers, strings, characters |
| Comments | -- line, /* multi-line */ |

### Contract Keywords

| Keyword | Purpose |
|---------|---------|
| require | Precondition |
| ensure | Postcondition |
| invariant | Class invariant |
| check | Runtime assertion |
| variant | Loop variant |
| old | Previous value in postcondition |
