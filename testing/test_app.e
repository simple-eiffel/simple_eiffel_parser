note
	description: "Test runner for simple_eiffel_parser - EiffelBase diagnostics"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run parser diagnostics
		do
			print ("=== SIMPLE_EIFFEL_PARSER DIAGNOSTIC ===%N%N")
			create parser.make

			-- Run lib_tests (EQA-style tests)
			run_lib_tests
			print ("%N")

			-- First test minimal cases to isolate the issue
			test_minimal_cases
			print ("%N")

			-- Then run full EiffelBase diagnostics
			print ("Testing against EiffelBase ELKS library%N%N")
			run_eiffelbase_diagnostics
			print_summary
		end

feature -- Lib Tests

	run_lib_tests
			-- Run EQA-style lib tests
		local
			l_tests: LIB_TESTS
			l_suite: EIFFEL_PARSER_TEST_SUITE
		do
			print ("=== LIB_TESTS ===%N%N")
			create l_tests

			run_single_test (agent l_tests.test_parser_make, "test_parser_make")
			run_single_test (agent l_tests.test_parse_simple_class, "test_parse_simple_class")
			run_single_test (agent l_tests.test_parse_class_with_feature, "test_parse_class_with_feature")
			run_single_test (agent l_tests.test_lexer_tokens, "test_lexer_tokens")
			run_single_test (agent l_tests.test_lexer_keywords, "test_lexer_keywords")
			run_single_test (agent l_tests.test_class_node_name, "test_class_node_name")
			run_single_test (agent l_tests.test_feature_node, "test_feature_node")
			run_single_test (agent l_tests.test_has_errors, "test_has_errors")
			run_single_test (agent l_tests.test_dbc_analyzer_make, "test_dbc_analyzer_make")
			run_single_test (agent l_tests.test_multi_file_parsing_isolation, "test_multi_file_parsing_isolation")

			-- SCOOP inline separate tests (GitHub Gobo 2024)
			run_single_test (agent l_tests.test_scoop_inline_separate, "test_scoop_inline_separate")
			run_single_test (agent l_tests.test_scoop_multiple_inline_separate, "test_scoop_multiple_inline_separate")

			-- EIFFEL_PARSER_TEST_SUITE tests (previously only ran via AutoTest)
			print ("%N=== EIFFEL_PARSER_TEST_SUITE ===%N%N")
			create l_suite
			run_single_test (agent l_suite.test_class_with_feature, "test_class_with_feature")
			run_single_test (agent l_suite.test_inheritance, "test_inheritance")
			run_single_test (agent l_suite.test_contracts, "test_contracts")
			run_single_test (agent l_suite.test_once_function, "test_once_function")
			run_single_test (agent l_suite.test_class_names_convenience, "test_class_names_convenience")
			run_single_test (agent l_suite.test_eifgens_metadata_parser, "test_eifgens_metadata_parser")
		end

	run_single_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and report result
		do
			print ("  Running " + a_name + "... ")
			a_test.call (Void)
			print ("[PASS]%N")
		rescue
			print ("[FAIL]%N")
		end

feature -- Minimal Tests

	test_minimal_cases
			-- Test minimal Eiffel constructs to isolate issues
		do
			print ("=== MINIMAL TEST CASES ===%N%N")

			test_case ("External with ensure", "[
class TEST
feature
	my_feature: STRING
		external "built_in"
		ensure
			not_empty: not Result.is_empty
		end
end
]")

			test_case ("Alias feature", "[
class TEST
feature
	plus alias "+" (other: INTEGER): INTEGER
		do
			Result := Current + other
		end
end
]")


			test_case ("Unicode alias", "[
class TEST
feature
	is_equal alias "~" (other: like Current): BOOLEAN
		do
			Result := True
		end
end
]")

			test_case ("Multi-line postcondition", "[
class TEST
feature
	compute: INTEGER
		do
			Result := 42
		ensure
			positive: Result > 0
			below_100: Result < 100
			exact: Result = 42
		end
end
]")

			test_case ("External built_in only", "[
class TEST
feature
	generator: STRING
		external "built_in"
		end
end
]")

			test_case ("Multiple aliases", "[
class TEST
feature
	conjuncted alias "and" alias "+" (other: BOOLEAN): BOOLEAN
		external "built_in"
		end
end
]")

		end

	test_case (a_name: STRING; a_source: STRING)
			-- Run a single test case
		local
			l_ast: EIFFEL_AST
		do
			l_ast := parser.parse_string (a_source)
			if l_ast.has_errors then
				print ("[FAIL] " + a_name + "%N")
				across l_ast.parse_errors as err loop
					print ("       " + err.message + "%N")
				end
			else
				print ("[PASS] " + a_name)
				if l_ast.classes.count > 0 then
					print (" (" + l_ast.classes.first.features.count.out + " features)")
				end
				print ("%N")
			end
		end

	debug_tokens (a_name: STRING; a_source: STRING)
			-- Show token stream for source
		local
			l_lexer: EIFFEL_LEXER
			l_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
			i: INTEGER
		do
			print ("%N=== " + a_name + " ===%N")
			create l_lexer.make (a_source)
			l_tokens := l_lexer.all_tokens
			from i := 1 until i > l_tokens.count.min (30) loop
				print ("  " + i.out + ": " + token_type_name (l_tokens[i].token_type) + " = '" + l_tokens[i].text + "'%N")
				i := i + 1
			end
		end

	token_type_name (a_type: INTEGER): STRING
			-- Human-readable token type name
		do
			inspect a_type
			when {EIFFEL_TOKEN}.Token_identifier then Result := "IDENT"
			when {EIFFEL_TOKEN}.Token_string then Result := "STRING"
			when {EIFFEL_TOKEN}.Keyword_class then Result := "CLASS"
			when {EIFFEL_TOKEN}.Keyword_feature then Result := "FEATURE"
			when {EIFFEL_TOKEN}.Keyword_do then Result := "DO"
			when {EIFFEL_TOKEN}.Keyword_end then Result := "END"
			when {EIFFEL_TOKEN}.Keyword_alias then Result := "ALIAS"
			when {EIFFEL_TOKEN}.Symbol_colon then Result := "COLON"
			when {EIFFEL_TOKEN}.Symbol_lparen then Result := "LPAREN"
			when {EIFFEL_TOKEN}.Symbol_rparen then Result := "RPAREN"
			when {EIFFEL_TOKEN}.Symbol_comma then Result := "COMMA"
			when {EIFFEL_TOKEN}.Token_operator then Result := "OP"
			else Result := "T" + a_type.out
			end
		end

feature -- Diagnostics

	parser: SIMPLE_EIFFEL_PARSER
			-- Parser instance

	passed_count: INTEGER
	failed_count: INTEGER
	error_categories: HASH_TABLE [INTEGER, STRING]

	run_eiffelbase_diagnostics
			-- Parse core EiffelBase files to identify issues
		local
			l_base_path: STRING
		do
			create error_categories.make (20)
			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/kernel/"

			-- Core foundation classes
			print ("=== Core Kernel Classes ===%N")
			parse_file (l_base_path + "any.e", "ANY")
			parse_file (l_base_path + "boolean.e", "BOOLEAN")
			parse_file (l_base_path + "integer_32.e", "INTEGER_32")
			parse_file (l_base_path + "character_8.e", "CHARACTER_8")
			parse_file (l_base_path + "array.e", "ARRAY")
			parse_file (l_base_path + "comparable.e", "COMPARABLE")
			parse_file (l_base_path + "hashable.e", "HASHABLE")
			parse_file (l_base_path + "numeric.e", "NUMERIC")

			-- String classes
			print ("%N=== String Classes ===%N")
			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/kernel/string/"
			parse_file (l_base_path + "string_8.e", "STRING_8")
			parse_file (l_base_path + "readable_string_8.e", "READABLE_STRING_8")
			parse_file (l_base_path + "immutable_string_8.e", "IMMUTABLE_STRING_8")
			parse_file (l_base_path + "string_32.e", "STRING_32")

			-- Structure classes
			print ("%N=== Structure Classes ===%N")
			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/structures/list/"
			parse_file (l_base_path + "arrayed_list.e", "ARRAYED_LIST")
			parse_file (l_base_path + "linked_list.e", "LINKED_LIST")

			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/structures/table/"
			parse_file (l_base_path + "hash_table.e", "HASH_TABLE")

			-- Exception classes
			print ("%N=== Exception Classes ===%N")
			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/kernel/exceptions/"
			parse_file (l_base_path + "exception.e", "EXCEPTION")
			parse_file (l_base_path + "exception_manager.e", "EXCEPTION_MANAGER")

			-- File/IO classes
			print ("%N=== IO Classes ===%N")
			l_base_path := "C:/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/base/elks/kernel/"
			parse_file (l_base_path + "file.e", "FILE")
			parse_file (l_base_path + "directory.e", "DIRECTORY")
		end

	parse_file (a_path: STRING; a_class_name: STRING)
			-- Parse a single file and report result
		local
			l_ast: EIFFEL_AST
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_with_name (a_path)
			if not l_file.exists then
				print ("  [SKIP] " + a_class_name + " - file not found%N")
			else
				l_ast := parser.parse_file (a_path)
				if l_ast.has_errors then
					failed_count := failed_count + 1
					print ("  [FAIL] " + a_class_name + "%N")
					across l_ast.parse_errors as err loop
						print ("         Line " + err.line.out + ": " + err.message + "%N")
						categorize_error (err.message)
					end
				else
					passed_count := passed_count + 1
					print ("  [PASS] " + a_class_name)
					if l_ast.classes.count > 0 then
						print (" (" + l_ast.classes.first.features.count.out + " features)")
					end
					print ("%N")
				end
			end
		end

	categorize_error (a_message: STRING)
			-- Track error categories
		local
			l_category: STRING
			l_count: INTEGER
		do
			if a_message.has_substring ("'end'") then
				l_category := "Missing/extra 'end'"
			elseif a_message.has_substring ("Incomplete feature") then
				l_category := "Incomplete feature"
			elseif a_message.has_substring ("Unexpected token") then
				l_category := "Unexpected token"
			elseif a_message.has_substring ("class name") then
				l_category := "Class parsing"
			else
				l_category := "Other"
			end

			if error_categories.has (l_category) then
				l_count := error_categories.item (l_category)
				error_categories.force (l_count + 1, l_category)
			else
				error_categories.put (1, l_category)
			end
		end

	print_summary
			-- Print final summary
		do
			print ("%N=== SUMMARY ===%N")
			print ("Passed: " + passed_count.out + "%N")
			print ("Failed: " + failed_count.out + "%N")
			print ("Success Rate: " + ((passed_count * 100) // (passed_count + failed_count).max (1)).out + "%%%N")

			if error_categories.count > 0 then
				print ("%N=== ERROR CATEGORIES ===%N")
				from
					error_categories.start
				until
					error_categories.after
				loop
					print ("  " + error_categories.key_for_iteration + ": " + error_categories.item_for_iteration.out + "%N")
					error_categories.forth
				end
			end
		end

end
