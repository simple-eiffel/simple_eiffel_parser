
## [0.1.1] - 2026-10-21

### Fixed
- Gobo 26.10 compatibility. `GOBO_PARSER_BRIDGE` judged parse success with
  `parser.syntax_error`, a query that no longer exists on the Gobo 26.10
  parser (3 × VEEN). It now uses the parsed class's own flag:
  `attached last_class as l_found and then not l_found.has_syntax_error`.
  That flag exists in both Gobo 25.12 and 26.10, so this builds on either.
- The obvious rename (`parser.has_syntax_error`) was rejected. It compiled
  and passed 19/19, but a probe showed it reported a class with a syntax error
  as parsed OK. The class-level flag gives True/False/False/False on the probe's
  four inputs (valid / bad body / missing `end` / garbage), the same as the
  original code on 25.12.
- Verified: clean build, 19/19 on Gobo 25.12 and 26.10.

### Added (2026-07-18)
- Structural contract extraction from the full Gobo AST. `EIFFEL_FEATURE_NODE`
  now carries `precondition_clauses` / `postcondition_clauses`, and
  `EIFFEL_CLASS_NODE` carries `invariant_clauses`, populated from
  `ET_FEATURE.preconditions/postconditions` and `ET_CLASS.invariants`
  (`ET_ASSERTIONS.count`). These count individual assertion clauses, not
  require/ensure keyword lines.
- `ET_DECORATED_AST_FACTORY.set_keep_all_comments (True)` is now enabled, so the
  AST retains comments (the mechanism Gobo's gedoc uses for pretty-printing).

### Notes
- Additive and backward compatible: new fields default to 0; existing queries
  (names, types, parents, precondition/postcondition text) are unchanged.
- Correction prompted by Eric Bezault: the Gobo parser does carry comments and
  contracts; earlier docs wrongly implied it could not.
