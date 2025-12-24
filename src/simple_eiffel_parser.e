note
	description: "[
		Facade class for Eiffel source code parsing - extracts symbols for LSP.

		Internally wraps Gobo's ET_EIFFEL_PARSER to provide a simple API.
		Converts Gobo's ET_CLASS to our EIFFEL_CLASS_NODE for easy consumption.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_EIFFEL_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser with Gobo backend
		do
			create gobo_bridge.make
			create internal_last_ast.make
		end

feature -- Access

	last_ast: EIFFEL_AST
			-- Result of last parse operation
		do
			Result := internal_last_ast
		end

feature -- Parsing

	parse_string (a_source: STRING): EIFFEL_AST
			-- Parse Eiffel source code string
			-- Returns AST with classes, features, inheritance, errors
		require
			source_not_void: a_source /= Void
		do
			create internal_last_ast.make

			if gobo_bridge.parse_string (a_source, "inline_source.e") then
				if attached gobo_bridge.last_class as lc then
					internal_last_ast.add_class (gobo_bridge.to_simple_class (lc))
				end
			else
				if attached gobo_bridge.last_error as err then
					internal_last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make (err, 1, 1))
				else
					internal_last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Parse error", 1, 1))
				end
			end

			Result := internal_last_ast
		ensure
			result_not_void: Result /= Void
		end

	parse_file (a_path: STRING): EIFFEL_AST
			-- Parse Eiffel source file
		require
			path_not_empty: a_path /= Void and then not a_path.is_empty
		do
			create internal_last_ast.make

			if gobo_bridge.parse_file (a_path) then
				if attached gobo_bridge.last_class as lc then
					internal_last_ast.add_class (gobo_bridge.to_simple_class (lc))
				end
			else
				if attached gobo_bridge.last_error as err then
					internal_last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make (err, 1, 1))
				else
					internal_last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Cannot parse file: " + a_path, 1, 1))
				end
			end

			Result := internal_last_ast
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

	gobo_bridge: GOBO_PARSER_BRIDGE
			-- Gobo parser bridge

	internal_last_ast: EIFFEL_AST
			-- Internal AST storage

invariant
	gobo_bridge_exists: gobo_bridge /= Void
	internal_ast_exists: internal_last_ast /= Void

end
