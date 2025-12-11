note
	description: "Test suite for Eiffel parser"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_PARSER_TEST_SUITE

inherit
	EQA_TEST_SET

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
			assert ("has creator", l_ast.classes.first.creators.has ("make"))
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
			assert ("parent name", l_ast.classes.first.parents.first.parent_name.is_equal ("PARENT"))
			assert ("has redefine", l_ast.classes.first.parents.first.redefines.has ("make"))
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

	test_eifgens_metadata_parser
			-- Test EIFGENs metadata parsing
		local
			l_meta: EIFGENS_METADATA_PARSER
		do
			-- Test with simple_json's EIFGENs
			create l_meta.make_with_path ("/d/prod/simple_json/EIFGENs/simple_json_tests/W_code")
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
			assert ("has classes", l_meta.class_count > 100) -- simple_json has 1000+ classes
			assert ("has features", l_meta.total_features > 500)
		end

end
