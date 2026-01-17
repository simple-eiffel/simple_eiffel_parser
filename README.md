<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_eiffel_parser

**[Documentation](https://simple-eiffel.github.io/simple_eiffel_parser/)** | **[GitHub](https://github.com/simple-eiffel/simple_eiffel_parser)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-green.svg)]()
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Lightweight Eiffel source code parser for extracting structural information. Designed for IDE tooling, code analysis, and documentation generation.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

**Developed using AI-assisted methodology:** Built interactively with Claude Opus 4.5 following rigorous Design by Contract principles.

## Overview

simple_eiffel_parser is a recursive descent parser that extracts structural information from Eiffel source code without performing full semantic analysis. It is optimized for speed and IDE use cases rather than compilation.

**What it extracts:**
- Class declarations (deferred, expanded, frozen)
- Feature signatures with types
- Arguments and local variables
- Preconditions and postconditions
- Inheritance relationships (rename, redefine, undefine, select)
- Header comments for documentation

**What it does not do:**
- Type checking or inference
- Semantic analysis
- Full expression parsing
- SCOOP semantics validation

## Quick Start

```eiffel
local
    parser: SIMPLE_EIFFEL_PARSER
    ast: EIFFEL_AST
do
    create parser.make
    ast := parser.parse_file ("my_class.e")

    across ast.classes as c loop
        print ("Class: " + c.name + "%N")
        across c.features as f loop
            print ("  Feature: " + f.name + "%N")
        end
    end
end
```

## Architecture

- **simple_eiffel_parser.e** - Facade class (107 lines)
- **eiffel_parser.e** - Recursive descent parser (871 lines)
- **eiffel_lexer.e** - Tokenizer (436 lines)
- **eiffel_token.e** - Token definitions (160 lines)
- Plus AST node classes for classes, features, arguments, locals, parents, errors

**Total: 2,327 lines of Eiffel code across 11 classes.**

## Dependencies

- [simple_file](https://github.com/simple-eiffel/simple_file) - File reading
- [simple_regex](https://github.com/simple-eiffel/simple_regex) - Pattern matching

## Building

```bash
export SIMPLE_EIFFEL_PARSER=/path/to/simple_eiffel_parser
export SIMPLE_FILE=/path/to/simple_file
export SIMPLE_REGEX=/path/to/simple_regex

ec.exe -batch -config simple_eiffel_parser.ecf -target simple_eiffel_parser_tests -c_compile
./EIFGENs/simple_eiffel_parser_tests/W_code/simple_eiffel_parser.exe
```

## Use Cases

The primary consumer is [simple_lsp](https://github.com/simple-eiffel/simple_lsp), the Eiffel LSP server. The parser provides symbol information for go-to-definition, hover documentation, code completion, and document outline.

## Roadmap

| Feature | Status |
|---------|--------|
| Basic parsing | **Complete** |
| Contract extraction | **Complete** |
| Error recovery | **Complete** |
| Comment preservation | **Complete** |
| Generic parsing | **Complete** |
| ECF parsing | Planned |
| Type resolution | Planned |

## License

MIT License

## Resources

- [Simple Eiffel Organization](https://github.com/simple-eiffel)
- [simple_lsp](https://github.com/simple-eiffel/simple_lsp)
- [Eiffel Language](https://www.eiffel.org/)
