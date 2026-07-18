
## [Unreleased] - 2026-07-18

### Added
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
