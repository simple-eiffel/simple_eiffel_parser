# 7S-04: SIMPLE-STAR Ecosystem Integration

**Library:** simple_eiffel_parser
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Ecosystem Dependencies

### Required Libraries
- **Gobo** - For SIMPLE_EIFFEL_PARSER backend (optional)

### No simple_* Dependencies
Core parsing is standalone.

## Integration Patterns

### With simple_oracle (DbC Heatmap)

```eiffel
-- Analyze library for DbC coverage
analyzer: DBC_ANALYZER
create analyzer.make

across library_files as f loop
    content := read_file (f)
    analyzer.analyze_file_content (content, class_name, lib_name, f)
end

print ("DbC Score: " + analyzer.total_score.out + "%%")
```

### With simple_dot (Visualization)

```eiffel
-- Visualize inheritance hierarchy
parser: EIFFEL_PARSER
graph: SIMPLE_DOT_GRAPH

ast := parser.parse_file ("my_class.e")
create graph.make_digraph ("Inheritance")

across ast.classes as cls loop
    graph.add_node (cls.name)
    across cls.parents as parent loop
        graph.add_edge (parent.name, cls.name)
    end
end
```

### With LSP Server

```eiffel
-- Extract symbols for IDE
parser: SIMPLE_EIFFEL_PARSER
create parser.make

ast := parser.parse_string (document_content)
across ast.classes as cls loop
    -- Report class symbol to LSP
    across cls.features as feat loop
        -- Report feature symbols
    end
end
```

## API Consistency

Follows simple_* patterns:
- **Multiple parsers** - Native and Gobo bridge
- **Clean AST model** - Typed nodes
- **Design by Contract** - Full DBC on AST nodes
