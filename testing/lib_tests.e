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


feature -- Test: Multi-file parsing isolation

	test_multi_file_parsing_isolation
			-- Test that parsing multiple files returns correct class names.
			-- Catches bug where Gobo accumulated classes and always returned first.
			-- FIX: parse_file must call reset_system before each parse.
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.parse_file"
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

			-- Create 3 temp files with different class names
			-- Use operating_environment.directory_separator for cross-platform
			l_path1 := l_temp + operating_environment.directory_separator.out + "alpha.e"
			l_path2 := l_temp + operating_environment.directory_separator.out + "beta.e"
			l_path3 := l_temp + operating_environment.directory_separator.out + "gamma.e"

			create l_file1.make_create_read_write (l_path1)
			l_file1.put_string ("class ALPHA feature value: INTEGER end")
			l_file1.close

			create l_file2.make_create_read_write (l_path2)
			l_file2.put_string ("class BETA feature name: STRING end")
			l_file2.close

			create l_file3.make_create_read_write (l_path3)
			l_file3.put_string ("class GAMMA feature flag: BOOLEAN end")
			l_file3.close

			-- Parse all three files with SAME parser instance
			create l_parser.make
			l_ast1 := l_parser.parse_file (l_path1)
			l_ast2 := l_parser.parse_file (l_path2)
			l_ast3 := l_parser.parse_file (l_path3)

			-- Each parse MUST return correct class name
			assert_false ("file1 no errors", l_ast1.has_errors)
			assert_strings_equal ("file1 is ALPHA", "ALPHA", l_ast1.classes.first.name)

			assert_false ("file2 no errors", l_ast2.has_errors)
			assert_strings_equal ("file2 is BETA", "BETA", l_ast2.classes.first.name)

			assert_false ("file3 no errors", l_ast3.has_errors)
			assert_strings_equal ("file3 is GAMMA", "GAMMA", l_ast3.classes.first.name)

			-- Cleanup temp files
			create l_file1.make_with_name (l_path1)
			if l_file1.exists then l_file1.delete end
			create l_file2.make_with_name (l_path2)
			if l_file2.exists then l_file2.delete end
			create l_file3.make_with_name (l_path3)
			if l_file3.exists then l_file3.delete end
		end

feature -- Test: SCOOP Inline Separate Parsing

	test_scoop_inline_separate
			-- Test parsing SCOOP inline separate blocks.
			-- Tests: `separate <expr> as <var> do ... end` syntax
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.parse_string"
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			create l_parser.make
			l_source := "[
class SCOOP_TEST
feature
	process (a_worker: separate WORKER)
		do
			separate a_worker as l_worker do
				l_worker.do_work
			end
		end
end
]"
			l_ast := l_parser.parse_string (l_source)
			assert_false ("scoop parsed without errors", l_ast.has_errors)
			assert_integers_equal ("one class", 1, l_ast.classes.count)
			assert_strings_equal ("class name", "SCOOP_TEST", l_ast.classes.first.name)
			assert_true ("has process feature", l_ast.classes.first.features.count > 0)
		end

	test_scoop_multiple_inline_separate
			-- Test parsing multiple inline separate arguments.
			-- Tests: `separate expr1 as var1, expr2 as var2 do ... end` syntax
		note
			testing: "covers/{SIMPLE_EIFFEL_PARSER}.parse_string"
		local
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			create l_parser.make
			l_source := "[
class MULTI_SCOOP_TEST
feature
	cooperate (a_w1, a_w2: separate WORKER)
		do
			separate a_w1 as l_w1, a_w2 as l_w2 do
				l_w1.sync_with (l_w2)
			end
		end
end
]"
			l_ast := l_parser.parse_string (l_source)
			assert_false ("multi-scoop parsed without errors", l_ast.has_errors)
			assert_strings_equal ("class name", "MULTI_SCOOP_TEST", l_ast.classes.first.name)
		end

end
