# 7S-05: SECURITY

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Security Considerations

### Input Validation

**Risk:** Malformed Eiffel code could cause:
- Infinite loops in parser
- Stack overflow from deep nesting
- Memory exhaustion from large files

**Mitigation:**
- Lenient mode with error recovery
- Bounded iteration in skip functions
- Application-level file size limits

### File Path Handling

**Risk:** Path traversal via parse_file

**Mitigation:**
- Application-level path validation
- Precondition: path_not_empty

### Code Execution

**Risk:** None - parser does not execute code

**Note:** Parsing external Eiffel code is inherently safe as it only extracts structure, never runs the code.

### Resource Exhaustion

**Risk:** Very large files or deeply nested code

**Mitigation:**
- Application should limit file sizes
- Parser has error recovery for unusual structures

## Security Checklist

- [ ] Validate file paths before parsing
- [ ] Limit input file sizes
- [ ] Handle parse errors gracefully
- [ ] Don't expose internal errors to users
- [ ] Log parsing failures for debugging

## Trust Model

**Trusted Input:** Developer's own code
**Untrusted Input:** External code (open source, user uploads)

For untrusted input:
- Use lenient mode
- Check parse_errors
- Limit processing time
