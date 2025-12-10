note
	description: "Facade class for Eiffel source code parsing - extracts symbols for LSP"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_EIFFEL_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser
		do
			create parser.make
		end

feature -- Access

	last_ast: EIFFEL_AST
			-- Result of last parse operation
		do
			Result := parser.last_ast
		end

feature -- Parsing

	parse_string (a_source: STRING): EIFFEL_AST
			-- Parse Eiffel source code string
			-- Returns AST with classes, features, inheritance, errors
		require
			source_not_void: a_source /= Void
		do
			Result := parser.parse_string (a_source)
		ensure
			result_not_void: Result /= Void
		end

	parse_file (a_path: STRING): EIFFEL_AST
			-- Parse Eiffel source file
		require
			path_not_empty: a_path /= Void and then not a_path.is_empty
		do
			Result := parser.parse_file (a_path)
		ensure
			result_not_void: Result /= Void
		end

feature -- Convenience

	class_names (a_source: STRING): ARRAYED_LIST [STRING]
			-- Get all class names from source
		require
			source_not_void: a_source /= Void
		local
			l_ast: EIFFEL_AST
		do
			l_ast := parse_string (a_source)
			create Result.make (l_ast.classes.count)
			across l_ast.classes as c loop
				Result.extend (c.name)
			end
		ensure
			result_not_void: Result /= Void
		end

	feature_names (a_source: STRING; a_class_name: STRING): ARRAYED_LIST [STRING]
			-- Get all feature names for a class
		require
			source_not_void: a_source /= Void
			class_name_not_empty: a_class_name /= Void and then not a_class_name.is_empty
		local
			l_ast: EIFFEL_AST
		do
			l_ast := parse_string (a_source)
			create Result.make (20)
			across l_ast.classes as c loop
				if c.name.is_case_insensitive_equal (a_class_name) then
					across c.features as f loop
						Result.extend (f.name)
					end
				end
			end
		ensure
			result_not_void: Result /= Void
		end

	has_errors (a_source: STRING): BOOLEAN
			-- Does source have parse errors?
		require
			source_not_void: a_source /= Void
		do
			Result := parse_string (a_source).has_errors
		end

feature {NONE} -- Implementation

	parser: EIFFEL_PARSER
			-- Internal parser

invariant
	parser_exists: parser /= Void

end
