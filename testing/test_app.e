note
	description: "Test runner for simple_eiffel_parser"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests
		do
			test_incomplete_feature_detection
		end

feature -- Tests

	test_incomplete_feature_detection
			-- Test that incomplete features (bare identifiers) generate errors
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

			print ("=== TEST: Incomplete Feature Detection ===%N")
			print ("Has errors: " + l_ast.has_errors.out + "%N")
			print ("Error count: " + l_ast.parse_errors.count.out + "%N")
			across l_ast.parse_errors as e loop
				print ("  Error: " + e.message + " at line " + e.line.out + "%N")
			end

			if l_ast.has_errors then
				print ("PASSED: Parser correctly detected incomplete feature%N")
			else
				print ("FAILED: Parser should have detected error for bare identifier 'asdfghjkl'%N")
			end
		end

end
