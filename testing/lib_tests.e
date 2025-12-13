note
	description: "Tests for SIMPLE_EIFFEL_PARSER"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Parser Creation

	test_parser_make
			-- Test parser creation.
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.make"
		local
			parser: SIMPLE_EIFFEL_PARSER
		do
			create parser.make
			assert_attached ("parser created", parser)
		end

feature -- Test: Parse Class

	test_parse_simple_class
			-- Test parsing simple class.
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.parse_string"
		local
			parser: SIMPLE_EIFFEL_PARSER
			ast: EIFFEL_AST
			source: STRING
		do
			create parser.make
			source := "class MY_CLASS%Nend"
			ast := parser.parse_string (source)
			assert_false ("no errors", ast.has_errors)
			assert_integers_equal ("one class", 1, ast.classes.count)
			assert_strings_equal ("class name", "MY_CLASS", ast.classes.first.name)
		end

	test_parse_class_with_feature
			-- Test parsing class with feature.
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.parse_string"
		local
			parser: SIMPLE_EIFFEL_PARSER
			ast: EIFFEL_AST
			source: STRING
		do
			create parser.make
			source := "class MY_CLASS%Nfeature%N  do_something%N    do%N    end%Nend"
			ast := parser.parse_string (source)
			assert_false ("no errors", ast.has_errors)
			assert_true ("has features", ast.classes.first.features.count > 0)
		end

feature -- Test: Lexer

	test_lexer_tokens
			-- Test lexer tokenization.
		note
			testing: "covers/{EIFFEL_LEXER}.all_tokens"
		local
			lexer: EIFFEL_LEXER
		do
			create lexer.make ("class FOO end")
			assert_true ("has tokens", lexer.all_tokens.count > 0)
		end

	test_lexer_keywords
			-- Test lexer keyword recognition.
		note
			testing: "covers/{EIFFEL_LEXER}.all_tokens"
		local
			lexer: EIFFEL_LEXER
		do
			create lexer.make ("class feature do end")
			assert_greater_than ("multiple tokens", lexer.all_tokens.count, 3)
		end

feature -- Test: AST Nodes

	test_class_node_name
			-- Test class node name.
		note
			testing: "covers/{EIFFEL_CLASS_NODE}.name"
		local
			node: EIFFEL_CLASS_NODE
		do
			create node.make ("MY_CLASS", 1, 1)
			assert_strings_equal ("name", "MY_CLASS", node.name)
		end

	test_feature_node
			-- Test feature node creation.
		note
			testing: "covers/{EIFFEL_FEATURE_NODE}.make"
		local
			node: EIFFEL_FEATURE_NODE
		do
			create node.make ("my_feature", 1, 1)
			assert_strings_equal ("name", "my_feature", node.name)
		end

feature -- Test: Error Handling

	test_has_errors
			-- Test error detection.
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.has_errors"
		local
			parser: SIMPLE_EIFFEL_PARSER
		do
			create parser.make
			assert_true ("invalid syntax has errors", parser.has_errors ("class { } end"))
		end

feature -- Test: DBC Analyzer

	test_dbc_analyzer_make
			-- Test DBC analyzer creation.
		note
			testing: "covers/{DBC_ANALYZER}.make"
		local
			analyzer: DBC_ANALYZER
		do
			create analyzer.make
			assert_attached ("analyzer created", analyzer)
		end

end
