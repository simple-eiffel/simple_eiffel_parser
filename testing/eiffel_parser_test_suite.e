note
	description: "Test suite for Eiffel parser"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_PARSER_TEST_SUITE

inherit
	TEST_SET_BASE

feature -- Tests

	test_simple_class
			-- Test parsing a simple class
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
class
	HELLO

feature

	greeting: STRING = "Hello World"

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			assert ("one class", l_ast.classes.count = 1)
			assert ("class name", l_ast.classes.first.name.is_equal ("HELLO"))
			assert ("one feature", l_ast.classes.first.features.count = 1)
			assert ("feature name", l_ast.classes.first.features.first.name.is_equal ("greeting"))
		end

	test_class_with_feature
			-- Test class with procedure
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
class
	FOO

create
	make

feature

	make
			-- Create instance
		do
			value := 42
		end

	value: INTEGER

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			assert ("class name", l_ast.classes.first.name.is_equal ("FOO"))
			assert_string_contains ("has_class_name", "FOO", l_ast.classes.first.name)
			assert_string_contains ("has_creator", "make", l_ast.classes.first.creators.first)
			assert ("two features", l_ast.classes.first.features.count = 2)
		end

	test_function_with_arguments
			-- Test function with arguments and return type
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_feature: EIFFEL_FEATURE_NODE
			l_source: STRING
		do
			l_source := "[
class
	MATH

feature

	add (a, b: INTEGER): INTEGER
			-- Add two integers
		do
			Result := a + b
		end

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			l_feature := l_ast.classes.first.features.first
			assert ("feature name", l_feature.name.is_equal ("add"))
			assert ("is function", l_feature.is_function)
			assert ("two args", l_feature.arguments.count = 2)
			assert ("arg1 name", l_feature.arguments[1].name.is_equal ("a"))
			assert ("arg1 type", l_feature.arguments[1].arg_type.is_equal ("INTEGER"))
			assert ("return type", attached l_feature.return_type as rt and then rt.is_equal ("INTEGER"))
		end

	test_inheritance
			-- Test inheritance parsing
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
class
	CHILD

inherit
	PARENT
		redefine
			make
		end

feature

	make
		do
		end

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			assert ("one parent", l_ast.classes.first.parents.count = 1)
			assert_string_contains ("has_parent", "PARENT", l_ast.classes.first.parents.first.parent_name)
			assert_string_contains ("has_redefine", "make", l_ast.classes.first.parents.first.redefines.first)
		end

	test_contracts
			-- Test require/ensure extraction
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_feature: EIFFEL_FEATURE_NODE
			l_source: STRING
		do
			l_source := "[
class
	CONTRACT_TEST

feature

	set_value (v: INTEGER)
		require
			positive: v > 0
		do
			value := v
		ensure
			value_set: value = v
		end

	value: INTEGER

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			l_feature := l_ast.classes.first.features.first
			assert ("has precondition", not l_feature.precondition.is_empty)
			assert ("has postcondition", not l_feature.postcondition.is_empty)
		end

	test_deferred_class
			-- Test deferred class parsing
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
deferred class
	ABSTRACT_THING

feature

	do_something
		deferred
		end

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			assert ("is deferred", l_ast.classes.first.is_deferred)
			assert ("feature is deferred", l_ast.classes.first.features.first.is_deferred)
		end

	test_once_function
			-- Test once function parsing
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_feature: EIFFEL_FEATURE_NODE
			l_source: STRING
		do
			l_source := "[
class
	SINGLETON

feature

	instance: SINGLETON
		once
			create Result.make
		end

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			assert ("no errors", not l_ast.has_errors)
			l_feature := l_ast.classes.first.features.first
			assert ("is once", l_feature.is_once)
		end

	test_lexer_keywords
			-- Test lexer recognizes keywords
		local
			l_lexer: EIFFEL_LEXER
			l_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
		do
			create l_lexer.make ("class HELLO feature do end")
			l_tokens := l_lexer.all_tokens

			assert ("5 tokens", l_tokens.count = 5)
			assert ("class keyword", l_tokens[1].token_type = {EIFFEL_TOKEN}.Keyword_class)
			assert ("identifier", l_tokens[2].token_type = {EIFFEL_TOKEN}.Token_identifier)
			assert ("feature keyword", l_tokens[3].token_type = {EIFFEL_TOKEN}.Keyword_feature)
			assert ("do keyword", l_tokens[4].token_type = {EIFFEL_TOKEN}.Keyword_do)
			assert ("end keyword", l_tokens[5].token_type = {EIFFEL_TOKEN}.Keyword_end)
		end

	test_lexer_strings
			-- Test lexer handles strings
		local
			l_lexer: EIFFEL_LEXER
			l_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
		do
			create l_lexer.make ("%"hello world%"")
			l_tokens := l_lexer.all_tokens

			assert ("one token", l_tokens.count = 1)
			assert ("is string", l_tokens.first.token_type = {EIFFEL_TOKEN}.Token_string)
		end

	test_class_names_convenience
			-- Test class_names convenience method
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_names: ARRAYED_LIST [STRING]
			l_source: STRING
		do
			l_source := "[
class FOO end
class BAR end
			]"

			create l_parser.make
			l_names := l_parser.class_names (l_source)

			assert ("two classes", l_names.count = 2)
		end

	test_unexpected_token_error
			-- Test that unexpected tokens in feature clauses generate errors
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
class
	CALCULATOR

feature

	add (a, b: INTEGER): INTEGER
		do
			Result := a + b
		end

	asdfghjkl

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			print ("Has errors: " + l_ast.has_errors.out + "%N")
			print ("Error count: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error: " + e.message + " at line " + e.line.out + "%N")
			end

			assert ("has errors", l_ast.has_errors)
			assert ("at least one error", l_ast.parse_errors.count >= 1)
		end

	test_keyword_in_string
			-- Test that keywords inside strings are NOT treated as keywords
		local
			l_lexer: EIFFEL_LEXER
			l_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
		do
			-- String containing "class" should be ONE Token_string, not keyword
			create l_lexer.make ("%"this has class in it%"")
			l_tokens := l_lexer.all_tokens

			print ("Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text=" + t.text + "%N")
			end

			assert ("one token", l_tokens.count = 1)
			assert ("is string type", l_tokens.first.token_type = {EIFFEL_TOKEN}.Token_string)
		end

	test_parser_with_keyword_in_string
			-- Test parser handles keyword inside string correctly
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			l_source := "[
class
	TEST_CLASS

feature

	log_something
		do
			print ("Found class: " + name)
		end

	name: STRING

end
			]"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			print ("Parser errors: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error: " + e.message + " at line " + e.line.out + ", col " + e.column.out + "%N")
			end

			assert ("no errors", not l_ast.has_errors)
			assert ("one class", l_ast.classes.count = 1)
		end


	test_multi_file_parsing_isolation
			-- Test that parsing multiple files in sequence returns correct class names.
			-- This test catches the bug where Gobo's system accumulated classes and
			-- find_parsed_class always returned the FIRST parsed class.
			-- FIX: parse_file must call reset_system before each parse.
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast1, l_ast2, l_ast3: EIFFEL_AST
			l_file1, l_file2, l_file3: PLAIN_TEXT_FILE
			l_path1, l_path2, l_path3: STRING
			l_exec: EXECUTION_ENVIRONMENT
			l_temp: STRING
		do
			create l_exec
			check attached l_exec.temporary_directory_path as l_tmp_path then
				l_temp := l_tmp_path.name.out
			end

			-- Create 3 temporary files with different class names
			l_path1 := l_temp + "/test_alpha.e"
			l_path2 := l_temp + "/test_beta.e"
			l_path3 := l_temp + "/test_gamma.e"

			-- Write first file: class ALPHA
			create l_file1.make_create_read_write (l_path1)
			l_file1.put_string ("class ALPHA feature value: INTEGER end")
			l_file1.close

			-- Write second file: class BETA
			create l_file2.make_create_read_write (l_path2)
			l_file2.put_string ("class BETA feature name: STRING end")
			l_file2.close

			-- Write third file: class GAMMA
			create l_file3.make_create_read_write (l_path3)
			l_file3.put_string ("class GAMMA feature flag: BOOLEAN end")
			l_file3.close

			-- Parse all three files in sequence using the SAME parser instance
			create l_parser.make
			l_ast1 := l_parser.parse_file (l_path1)
			l_ast2 := l_parser.parse_file (l_path2)
			l_ast3 := l_parser.parse_file (l_path3)

			-- CRITICAL: Each parse must return the correct class name, not the first one
			print ("File 1 class: " + l_ast1.classes.first.name + " (expected ALPHA)%N")
			print ("File 2 class: " + l_ast2.classes.first.name + " (expected BETA)%N")
			print ("File 3 class: " + l_ast3.classes.first.name + " (expected GAMMA)%N")

			-- These assertions WILL FAIL if reset_system is not called in parse_file
			assert ("file1 parsed ok", not l_ast1.has_errors)
			assert ("file1 is ALPHA", l_ast1.classes.first.name.is_equal ("ALPHA"))

			assert ("file2 parsed ok", not l_ast2.has_errors)
			assert ("file2 is BETA", l_ast2.classes.first.name.is_equal ("BETA"))

			assert ("file3 parsed ok", not l_ast3.has_errors)
			assert ("file3 is GAMMA", l_ast3.classes.first.name.is_equal ("GAMMA"))

			-- Cleanup
			create l_file1.make_with_name (l_path1)
			if l_file1.exists then l_file1.delete end
			create l_file2.make_with_name (l_path2)
			if l_file2.exists then l_file2.delete end
			create l_file3.make_with_name (l_path3)
			if l_file3.exists then l_file3.delete end
		end
	test_eifgens_metadata_parser
			-- Test EIFGENs metadata parsing
		local
			l_meta: EIFGENS_METADATA_PARSER
			l_env: SIMPLE_ENV
		do
			create l_env
			check attached l_env.item ("SIMPLE_EIFFEL") as al_root then
				-- Test with simple_json's EIFGENs
				create l_meta.make_with_path (al_root + "/simple_json/EIFGENs/simple_json_tests/W_code")
				l_meta.load

				print ("Loaded: " + l_meta.is_loaded.out + "%N")
				print ("Classes: " + l_meta.class_count.out + "%N")
				print ("Features: " + l_meta.total_features.out + "%N")

				-- Test class lookup
				if l_meta.has_class ("SIMPLE_JSON") then
					print ("Found SIMPLE_JSON at index: " + l_meta.class_index ("SIMPLE_JSON").out + "%N")
				else
					print ("SIMPLE_JSON not found!%N")
				end

				-- Test ancestor chain
				if l_meta.has_class ("SIMPLE_JSON_VALUE") then
					print ("Ancestors of SIMPLE_JSON_VALUE: ")
					across l_meta.ancestor_chain ("SIMPLE_JSON_VALUE") as a loop
						print (a + " ")
					end
					print ("%N")
				end

				assert ("metadata loaded", l_meta.is_loaded)
				assert_in_range ("has_classes", l_meta.class_count, 100, 10_000)
				assert_in_range ("has_features", l_meta.total_features, 100, 10_000)
			end
		end

end
