# S05: CONSTRAINTS

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Technical Constraints

### Source Constraints

| Constraint | Enforcement | Reason |
|------------|-------------|--------|
| Source not void | Precondition | Required input |
| Path not empty | Precondition | File operations |
| Valid UTF-8 | Assumption | Eiffel standard |

### AST Node Constraints

| Field | Constraint | Enforcement |
|-------|------------|-------------|
| name | Not empty | Invariant |
| line | >= 1 | Invariant |
| column | >= 1 | Invariant |
| kind | Valid range | Invariant |

### Token Constraints

| Constraint | Enforcement |
|------------|-------------|
| token_type valid | Constructor |
| text not void | Constructor |
| line >= 1 | Constructor |
| column >= 1 | Constructor |

## Behavioral Constraints

### Parser Behavior

**Error Recovery:**
- Skip to next recognizable construct
- Report error but continue parsing
- Partial AST better than no AST

**Class Modifiers:**
- deferred, expanded, frozen mutually compatible
- Order: deferred/expanded/frozen then class

**Feature Kinds:**
- Attribute: has type, no body keywords
- Procedure: has do/once, no return type
- Function: has do/once, has return type
- Deferred: has deferred keyword
- External: has external keyword

### DbC Scoring Constraints

**Score Range:** 0-100
**Formula:** (contract_lines * 50) / features, capped at 100

**Interpretation:**
- 0: No contracts
- 1-24: Minimal
- 25-49: Partial
- 50-74: Good
- 75-89: Strong
- 90-100: Excellent
