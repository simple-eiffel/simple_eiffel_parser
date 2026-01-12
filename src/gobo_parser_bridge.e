note
	description: "[
		Bridge between Gobo ET_EIFFEL_PARSER and simple_eiffel_parser API.

		Provides simple parsing of Eiffel source files and strings.
		Extracts class names, features, parents, and types.

		Limitations (Gobo library constraints):
		- C3 character constants ('%/code/') trigger precondition failure in
		  ET_DECORATED_AST_FACTORY. Affected files (STRING_8, HASH_TABLE, etc.)
		  are caught by rescue/retry and reported as parse exceptions.
		- For files with C3 constants, use Gobo directly with ET_AST_FACTORY.
	]"
	author: "Larry Rix"
	date: "$Date$"

class
	GOBO_PARSER_BRIDGE

inherit
	ET_SHARED_TOKEN_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser bridge
		local
			l_ast_factory: ET_DECORATED_AST_FACTORY
		do
			create system.make ("simple_parser_system")
			create system_processor.make
			system_processor.set_benchmark_shown (False)
			system_processor.set_nested_benchmark_shown (False)
			system_processor.set_preparse_shallow_mode

			-- Use decorated AST factory to preserve whitespace/comments
			create l_ast_factory.make
			l_ast_factory.set_keep_all_breaks (True)
			system_processor.set_ast_factory (l_ast_factory)

			-- Create our subclass of the parser that exposes last_class
			create parser.make (system_processor)
		end

feature -- Access

	system: ET_SYSTEM
			-- Gobo system context

	system_processor: ET_SYSTEM_PROCESSOR
			-- System processor for parsing configuration

	parser: SIMPLE_GOBO_PARSER
			-- Gobo Eiffel parser (with exposed last_class)

	last_class: detachable ET_CLASS
			-- Last parsed class

	last_error: detachable STRING
			-- Last error message if parsing failed

	last_filename_mismatch: detachable TUPLE [actual_path: STRING; derived_filename: STRING]
			-- Set when filename did not match class name and fallback was used.
			-- Caller can log this to KB or elsewhere. Void if no mismatch.

feature -- Parsing

	parse_file (a_path: STRING): BOOLEAN
			-- Parse file at `a_path'. Return True on success.
		require
			path_valid: a_path /= Void and then not a_path.is_empty
		local
			l_file: KL_TEXT_INPUT_FILE
			l_cluster: ET_CLUSTER
			l_time_stamp: INTEGER
			l_retried: BOOLEAN
			l_source: STRING
			l_derived_filename: STRING
			l_stream: KL_STRING_INPUT_STREAM
		do
			if l_retried then
				last_error := "Parser exception (possibly unsupported character constant)"
				Result := False
			else
				last_error := Void
				last_class := Void
				last_filename_mismatch := Void

				-- Reset system to avoid class accumulation between parses
				reset_system

				-- Create a temporary cluster for the file
				create l_cluster.make ("temp_cluster", ".", system)

				-- Open and parse the file directly (Gobo handles most encodings)
				create l_file.make (a_path)
				l_file.open_read

				if l_file.is_open_read then
					l_time_stamp := l_file.time_stamp
					parser.parse_file (l_file, a_path, l_time_stamp, l_cluster)
					l_file.close

					-- After parsing, find the parsed class in the system
					last_class := find_parsed_class
					if last_class /= Void then
						Result := not parser.syntax_error
					else
						-- FALLBACK: Read content, strip BOM if present, try again
						l_file.open_read
						if l_file.is_open_read then
							l_source := read_file_content (l_file)
							l_file.close
							l_source := strip_bom (l_source)
							l_derived_filename := derive_filename_from_source (l_source)

							-- Retry with derived filename or after BOM stripping
							reset_system
							create l_cluster.make ("temp_cluster", ".", system)
							create l_stream.make (l_source)
							parser.parse_file (l_stream, l_derived_filename, l_time_stamp, l_cluster)

							last_class := find_parsed_class
							if last_class /= Void then
								if not a_path.has_substring (l_derived_filename) then
									last_filename_mismatch := [a_path, l_derived_filename]
								end
								Result := not parser.syntax_error
							else
								last_error := "No class found (tried both paths)"
								Result := False
							end
						else
							last_error := "No class found in file"
							Result := False
						end
					end
				else
					last_error := "Cannot open file: " + a_path
					Result := False
				end
			end
		rescue
			l_retried := True
			retry
		end

	parse_string (a_source: STRING; a_filename: STRING): BOOLEAN
			-- Parse source string as if from `a_filename'. Return True on success.
			-- Note: filename should match class name (e.g., "my_class.e" for "class MY_CLASS")
		require
			source_valid: a_source /= Void
			filename_valid: a_filename /= Void and then not a_filename.is_empty
		local
			l_stream: KL_STRING_INPUT_STREAM
			l_cluster: ET_CLUSTER
			l_retried: BOOLEAN
			l_actual_filename: STRING
		do
			if l_retried then
				last_error := "Parser exception"
				Result := False
			else
				last_error := Void
				last_class := Void
				last_filename_mismatch := Void

				-- Reset system to avoid class accumulation between parses
				reset_system

				-- Extract class name from source and use as filename (Gobo shallow mode requirement)
				l_actual_filename := derive_filename_from_source (a_source)

				-- Create a temporary cluster
				create l_cluster.make ("temp_cluster", ".", system)

				-- Create a string stream for the source
				create l_stream.make (a_source)

				parser.parse_file (l_stream, l_actual_filename, -1, l_cluster)

				-- After parsing, find the parsed class in the system
				last_class := find_parsed_class
				if last_class /= Void then
					Result := not parser.syntax_error
				else
					last_error := "No class found in source"
					Result := False
				end
			end
		rescue
			l_retried := True
			retry
		end

	find_parsed_class: detachable ET_CLASS
			-- Find the most recently parsed class in the system
		do
			-- Look in the system for any parsed class
			find_result_cell.put (Void)
			system.classes_do_if_recursive (
				agent store_first_class,
				agent {ET_CLASS}.is_parsed
			)
			Result := find_result_cell.item
		end

	store_first_class (a_class: ET_CLASS)
			-- Store a_class in find_result_cell if empty
		do
			if find_result_cell.item = Void then
				find_result_cell.put (a_class)
			end
		end

	find_result_cell: CELL [detachable ET_CLASS]
			-- Helper cell for find_parsed_class
		once
			create Result.put (Void)
		end

feature {NONE} -- Implementation

	read_file_content (a_file: KL_TEXT_INPUT_FILE): STRING
			-- Read entire file content into string
		require
			file_open: a_file.is_open_read
		do
			create Result.make (4096)
			from
			until
				a_file.end_of_file
			loop
				a_file.read_line
				if attached a_file.last_string as line then
					Result.append (line)
					Result.append_character ('%N')
				end
			end
		ensure
			result_not_void: Result /= Void
		end

	strip_bom (a_source: STRING): STRING
			-- Remove UTF-8 BOM (Byte Order Mark) if present at start of string.
			-- BOM is EF BB BF in UTF-8, which appears as character 65279 (0xFEFF) in UTF-8.
		do
			Result := a_source
			-- UTF-8 BOM appears as three bytes: 0xEF 0xBB 0xBF
			-- When read as ISO-8859-1 characters they appear as specific codes
			if Result.count >= 3 then
				if Result.item (1).code = 0xEF and Result.item (2).code = 0xBB and Result.item (3).code = 0xBF then
					Result := Result.substring (4, Result.count)
				end
			end
			-- Also check for single character BOM (when file is read as UTF-8)
			if Result.count >= 1 and then Result.item (1).code = 0xFEFF then
				Result := Result.substring (2, Result.count)
			end
		ensure
			result_not_void: Result /= Void
		end

	derive_filename_from_source (a_source: STRING): STRING
			-- Extract class name from source and return "classname.e"
			-- Gobo requires filename to match class name in shallow mode
		local
			i, j: INTEGER
			l_upper: STRING
		do
			-- Find "class" keyword followed by class name
			l_upper := a_source.as_upper
			i := l_upper.substring_index ("CLASS", 1)
			if i > 0 then
				-- Skip "class" and whitespace
				from i := i + 5 until i > a_source.count or else not a_source.item (i).is_space loop
					i := i + 1
				end
				-- Find end of class name
				from j := i until j > a_source.count or else not (a_source.item (j).is_alpha or a_source.item (j).is_digit or a_source.item (j) = '_') loop
					j := j + 1
				end
				if j > i then
					Result := a_source.substring (i, j - 1).as_lower + ".e"
				else
					Result := "unknown.e"
				end
			else
				Result := "unknown.e"
			end
		ensure
			result_not_empty: Result /= Void and then not Result.is_empty
		end

	reset_system
			-- Create fresh system to avoid class accumulation between parses
		local
			l_ast_factory: ET_DECORATED_AST_FACTORY
		do
			create system.make ("simple_parser_system")
			create system_processor.make
			system_processor.set_benchmark_shown (False)
			system_processor.set_nested_benchmark_shown (False)
			system_processor.set_preparse_shallow_mode

			-- Use decorated AST factory to preserve whitespace/comments
			create l_ast_factory.make
			l_ast_factory.set_keep_all_breaks (True)
			system_processor.set_ast_factory (l_ast_factory)

			-- Create our subclass of the parser that exposes last_class
			create parser.make (system_processor)
		end

feature -- Conversion

	to_simple_class (a_class: ET_CLASS): EIFFEL_CLASS_NODE
			-- Convert Gobo ET_CLASS to simple EIFFEL_CLASS_NODE
		require
			a_class_not_void: a_class /= Void
		local
			l_feature: EIFFEL_FEATURE_NODE
			i: INTEGER
		do
			-- Use 1,1 for position - Gobo doesn't expose source positions easily
			create Result.make (a_class.name.name, 1, 1)

			-- Set class modifiers
			Result.set_deferred (a_class.is_deferred)
			Result.set_expanded (a_class.is_expanded)
			Result.set_frozen (a_class.is_frozen)

			-- Extract queries (functions and attributes)
			if attached a_class.queries as queries then
				from i := 1 until i > queries.count loop
					if attached queries.item (i) as q then
						l_feature := query_to_feature (q)
						Result.add_feature (l_feature)
					end
					i := i + 1
				end
			end

			-- Extract procedures
			if attached a_class.procedures as procedures then
				from i := 1 until i > procedures.count loop
					if attached procedures.item (i) as p then
						l_feature := procedure_to_feature (p)
						Result.add_feature (l_feature)
					end
					i := i + 1
				end
			end

			-- Extract parents
			if attached a_class.parent_clauses as pcl then
				extract_parents (a_class, Result)
			end
		end

feature {NONE} -- Conversion helpers

	query_to_feature (a_query: ET_QUERY): EIFFEL_FEATURE_NODE
			-- Convert ET_QUERY to EIFFEL_FEATURE_NODE
		require
			query_valid: a_query /= Void
		local
			l_type_name: STRING
		do
			-- Get feature name (use 1,1 for position - Gobo doesn't expose easily)
			create Result.make (a_query.name.name, 1, 1)

			-- Get return type
			if attached a_query.type as t then
				l_type_name := type_to_string (t)
				Result.set_return_type (l_type_name)
			end

			-- Mark as function or attribute
			if attached {ET_FUNCTION} a_query as func then
				Result.set_kind ({EIFFEL_FEATURE_NODE}.Kind_function)
				extract_arguments (func, Result)
			else
				Result.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
			end

			-- Check for deferred
			if a_query.is_deferred then
				Result.set_deferred (True)
			end
		end

	procedure_to_feature (a_procedure: ET_PROCEDURE): EIFFEL_FEATURE_NODE
			-- Convert ET_PROCEDURE to EIFFEL_FEATURE_NODE
		require
			procedure_valid: a_procedure /= Void
		do
			create Result.make (a_procedure.name.name, 1, 1)
			Result.set_kind ({EIFFEL_FEATURE_NODE}.Kind_procedure)

			-- Extract arguments
			extract_arguments (a_procedure, Result)

			-- Check for deferred
			if a_procedure.is_deferred then
				Result.set_deferred (True)
			end
		end

	extract_arguments (a_routine: ET_ROUTINE; a_feature: EIFFEL_FEATURE_NODE)
			-- Extract arguments from routine into feature node
		require
			routine_valid: a_routine /= Void
			feature_valid: a_feature /= Void
		local
			l_arg: EIFFEL_ARGUMENT_NODE
			l_type_name: STRING
			l_arg_count: INTEGER
			i: INTEGER
		do
			if attached a_routine.arguments as args then
				from i := 1 until i > args.count loop
					if attached args.item (i) as arg_item then
						-- Each item has a formal_argument with name and type
						if attached arg_item.formal_argument as formal_arg then
							l_arg_count := l_arg_count + 1
							l_type_name := type_to_string (formal_arg.type)
							create l_arg.make (formal_arg.name.name, l_type_name, l_arg_count)
							a_feature.add_argument (l_arg)
						end
					end
					i := i + 1
				end
			end
		end

	extract_parents (a_class: ET_CLASS; a_result: EIFFEL_CLASS_NODE)
			-- Extract parent classes
		local
			l_parent: EIFFEL_PARENT_NODE
			i, j: INTEGER
		do
			if attached a_class.parent_clauses as clause_list then
				-- Iterate over parent clause list (ET_PARENT_CLAUSE_LIST contains ET_PARENT_LIST)
				from i := 1 until i > clause_list.count loop
					if attached clause_list.item (i) as parent_list then
						-- Iterate over parent list (ET_PARENT_LIST has parent(i) returning ET_PARENT)
						from j := 1 until j > parent_list.count loop
							if attached parent_list.parent (j) as p then
								if attached p.type as t then
									create l_parent.make (type_to_string (t))
									a_result.add_parent (l_parent)
								end
							end
							j := j + 1
						end
					end
					i := i + 1
				end
			end
		end

	type_to_string (a_type: ET_TYPE): STRING
			-- Convert ET_TYPE to string representation
		require
			type_valid: a_type /= Void
		do
			if attached {ET_CLASS_TYPE} a_type as class_type then
				Result := class_type.name.name.as_upper
			elseif attached {ET_LIKE_CURRENT} a_type then
				Result := "like Current"
			elseif attached {ET_LIKE_FEATURE} a_type as like_feat then
				Result := "like " + like_feat.name.name
			else
				-- Fallback: use generic string representation
				create Result.make (50)
				a_type.append_to_string (Result)
			end
		ensure
			result_not_void: Result /= Void
		end

end
