note
	description: "Quick test for string lexing with keywords"

class
	TEST_STRING_LEXER

create
	make

feature

	make
		local
			l_lexer: EIFFEL_LEXER
			l_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
			l_parser: SIMPLE_EIFFEL_PARSER
			l_ast: EIFFEL_AST
			l_source: STRING
		do
			print ("Testing lexer with keywords inside strings...%N%N")

			-- Test 1: Simple string with class keyword
			print ("Test 1: String containing 'class'%N")
			create l_lexer.make ("%"this has class in it%"")
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 2: Multiple tokens with string in middle
			print ("Test 2: identifier + string + identifier%N")
			create l_lexer.make ("foo %"has class%"  bar")
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 3: print statement with string
			print ("Test 3: print with 'class' in string%N")
			create l_lexer.make ("print (%"Found class: %")")
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 4: Verbatim string lexing
			print ("Test 4: Verbatim string with 'class' inside%N")
			l_source := "%"[%Nclass%N	TEST_CLASS%Nfeature%Nend%N]%""
			print ("  Source: (verbatim string)%N")
			create l_lexer.make (l_source)
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 5: Full class with string containing 'class' (not verbatim)
			print ("Test 5: Parse class with 'class' in string%N")
			l_source := "class TEST_CLASS feature log_something do print (%"Found class: %" + name) end name: STRING end"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			print ("  Parse errors: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error at line " + e.line.out + ", col " + e.column.out + ": " + e.message + "%N")
			end
			print ("  Classes found: " + l_ast.classes.count.out + "%N")
			print ("%N")

			-- Test 6: Multi-line class with strings
			print ("Test 6: Multi-line class with 'class' in string%N")
			l_source := "class%N%TTEST_CLASS%N%Nfeature%N%N%Tlog_something%N%T%Tdo%N%T%T%Tprint (%"Found class: %" + name)%N%T%Tend%N%N%Tname: STRING%N%Nend"

			create l_parser.make
			l_ast := l_parser.parse_string (l_source)

			print ("  Parse errors: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error at line " + e.line.out + ", col " + e.column.out + ": " + e.message + "%N")
			end
			print ("  Classes found: " + l_ast.classes.count.out + "%N")
			print ("%N")

			-- Test 7: Verbatim string like in note clause
			print ("Test 7: Verbatim string in note%N")
			l_source := "note%N%Tdescription: %"[%N%T%TMain LSP server.%N%T]%"%N%Nclass%N%TTEST"
			create l_lexer.make (l_source)
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " line=" + t.line.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 8: Empty string
			print ("Test 8: Empty string%N")
			l_source := "x %"%""
			create l_lexer.make (l_source)
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 9: Line 1119 pattern - empty string in if expression
			print ("Test 9: Empty string in if expression%N")
			l_source := "if attached x as y then y else %"%" end"
			create l_lexer.make (l_source)
			l_tokens := l_lexer.all_tokens
			print ("  Token count: " + l_tokens.count.out + "%N")
			across l_tokens as t loop
				print ("  Token: type=" + t.token_type.out + " text='" + t.text + "'%N")
			end
			print ("%N")

			-- Test 10: First multi-line string in lsp_server.e
			print ("Test 10: Find first bad string in lsp_server.e%N")
			l_source := read_file ("D:\prod\simple_lsp\src\lsp_server.e")
			create l_lexer.make (l_source)
			l_tokens := l_lexer.all_tokens
			across l_tokens as t loop
				if t.token_type = 4 and t.text.has ('%N') then
					print ("  MULTI-LINE STRING at line=" + t.line.out + " col=" + t.column.out + " len=" + t.text.count.out + "%N")
					print ("    start='" + t.text.substring (1, t.text.count.min (50)) + "'%N")
					print ("    end='" + t.text.substring ((t.text.count - 50).max (1), t.text.count) + "'%N")
				end
			end
			print ("%N")

			-- Test 11: Parse the actual lsp_server.e file
			print ("Test 11: Parse lsp_server.e%N")
			create l_parser.make
			l_ast := l_parser.parse_file ("D:\prod\simple_lsp\src\lsp_server.e")

			print ("  Parse errors: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error at line " + e.line.out + ", col " + e.column.out + ": " + e.message + "%N")
			end
			print ("  Classes found: " + l_ast.classes.count.out + "%N")
			print ("%N")

			print ("Done.%N")
		end

	read_file (a_path: STRING): STRING
			-- Read file contents
		local
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				Result := l_file.last_string
				l_file.close
			else
				Result := ""
			end
		end

end
