note
	description: "Lexer/tokenizer for Eiffel source code"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_LEXER

create
	make,
	make_from_string

feature {NONE} -- Initialization

	make (a_source: STRING)
			-- Initialize lexer with source code
		require
			source_not_void: a_source /= Void
		do
			source := a_source
			position := 1
			line := 1
			column := 1
			create keywords.make (60)
			initialize_keywords
		ensure
			source_set: source = a_source
			position_at_start: position = 1
		end

	make_from_string (a_source: STRING)
			-- Alias for make
		require
			source_not_void: a_source /= Void
		do
			make (a_source)
		end

feature -- Access

	source: STRING
			-- Source code being tokenized

	position: INTEGER
			-- Current position in source

	line: INTEGER
			-- Current line number

	column: INTEGER
			-- Current column number

feature -- Tokenization

	next_token: EIFFEL_TOKEN
			-- Get next token from source
		local
			c: CHARACTER
		do
			skip_whitespace

			if position > source.count then
				create Result.make ({EIFFEL_TOKEN}.Token_eof, "", line, column)
			else
				c := source[position]
				if c = '-' and then position + 1 <= source.count and then source[position + 1] = '-' then
					Result := scan_comment
				elseif c = '"' then
					Result := scan_string
				elseif c = '%'' then
					Result := scan_character
				elseif c.is_alpha or c = '_' then
					Result := scan_identifier_or_keyword
				elseif c.is_digit then
					Result := scan_number
				else
					Result := scan_symbol
				end
			end
		ensure
			result_not_void: Result /= Void
		end

	all_tokens: ARRAYED_LIST [EIFFEL_TOKEN]
			-- Get all tokens from source
		local
			tok: EIFFEL_TOKEN
		do
			create Result.make (100)
			from
				position := 1
				line := 1
				column := 1
				tok := next_token
			until
				tok.is_eof
			loop
				Result.extend (tok)
				tok := next_token
			end
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Scanning

	scan_comment: EIFFEL_TOKEN
			-- Scan a comment (-- to end of line)
		local
			start_col: INTEGER
			start_pos: INTEGER
			text: STRING
		do
			start_col := column
			start_pos := position
			from
			until
				position > source.count or else source[position] = '%N'
			loop
				advance
			end
			text := source.substring (start_pos, position - 1)
			create Result.make ({EIFFEL_TOKEN}.Token_comment, text, line, start_col)
		end

	scan_string: EIFFEL_TOKEN
			-- Scan a string literal
		local
			start_col: INTEGER
			start_pos: INTEGER
			text: STRING
		do
			start_col := column
			start_pos := position
			advance -- skip opening quote
			from
			until
				position > source.count or else (source[position] = '"' and then (position = 1 or else source[position - 1] /= '%%'))
			loop
				if source[position] = '%N' then
					line := line + 1
					column := 0
				end
				advance
			end
			if position <= source.count then
				advance -- skip closing quote
			end
			text := source.substring (start_pos, position - 1)
			create Result.make ({EIFFEL_TOKEN}.Token_string, text, line, start_col)
		end

	scan_character: EIFFEL_TOKEN
			-- Scan a character literal
		local
			start_col: INTEGER
			start_pos: INTEGER
			text: STRING
		do
			start_col := column
			start_pos := position
			advance -- skip opening quote
			if position <= source.count and then source[position] = '%%' then
				advance -- skip escape char
				if position <= source.count then
					advance -- skip escaped char
				end
			elseif position <= source.count then
				advance -- skip char
			end
			if position <= source.count and then source[position] = '%'' then
				advance -- skip closing quote
			end
			text := source.substring (start_pos, position - 1)
			create Result.make ({EIFFEL_TOKEN}.Token_character, text, line, start_col)
		end

	scan_identifier_or_keyword: EIFFEL_TOKEN
			-- Scan an identifier or keyword
		local
			start_col: INTEGER
			start_pos: INTEGER
			text: STRING
			lower_text: STRING
			keyword_type: INTEGER
		do
			start_col := column
			start_pos := position
			from
			until
				position > source.count or else not (source[position].is_alpha or source[position].is_digit or source[position] = '_')
			loop
				advance
			end
			text := source.substring (start_pos, position - 1)
			lower_text := text.as_lower

			if keywords.has (lower_text) then
				keyword_type := keywords[lower_text]
				create Result.make (keyword_type, text, line, start_col)
			else
				create Result.make ({EIFFEL_TOKEN}.Token_identifier, text, line, start_col)
			end
		end

	scan_number: EIFFEL_TOKEN
			-- Scan a numeric literal
		local
			start_col: INTEGER
			start_pos: INTEGER
			text: STRING
			is_real: BOOLEAN
		do
			start_col := column
			start_pos := position
			from
			until
				position > source.count or else not source[position].is_digit
			loop
				advance
			end
			-- Check for decimal point
			if position <= source.count and then source[position] = '.' and then position + 1 <= source.count and then source[position + 1].is_digit then
				is_real := True
				advance -- skip dot
				from
				until
					position > source.count or else not source[position].is_digit
				loop
					advance
				end
			end
			-- Check for exponent
			if position <= source.count and then (source[position] = 'e' or source[position] = 'E') then
				is_real := True
				advance
				if position <= source.count and then (source[position] = '+' or source[position] = '-') then
					advance
				end
				from
				until
					position > source.count or else not source[position].is_digit
				loop
					advance
				end
			end
			text := source.substring (start_pos, position - 1)
			if is_real then
				create Result.make ({EIFFEL_TOKEN}.Token_real, text, line, start_col)
			else
				create Result.make ({EIFFEL_TOKEN}.Token_integer, text, line, start_col)
			end
		end

	scan_symbol: EIFFEL_TOKEN
			-- Scan a symbol or operator
		local
			start_col: INTEGER
			c: CHARACTER
			token_type: INTEGER
			text: STRING
		do
			start_col := column
			c := source[position]
			text := c.out

			inspect c
			when ':' then
				advance
				if position <= source.count and then source[position] = '=' then
					text := ":="
					token_type := {EIFFEL_TOKEN}.Symbol_assign
					advance
				else
					token_type := {EIFFEL_TOKEN}.Symbol_colon
				end
			when ';' then
				token_type := {EIFFEL_TOKEN}.Symbol_semicolon
				advance
			when ',' then
				token_type := {EIFFEL_TOKEN}.Symbol_comma
				advance
			when '.' then
				token_type := {EIFFEL_TOKEN}.Symbol_dot
				advance
			when '(' then
				token_type := {EIFFEL_TOKEN}.Symbol_lparen
				advance
			when ')' then
				token_type := {EIFFEL_TOKEN}.Symbol_rparen
				advance
			when '[' then
				token_type := {EIFFEL_TOKEN}.Symbol_lbracket
				advance
			when ']' then
				token_type := {EIFFEL_TOKEN}.Symbol_rbracket
				advance
			when '{' then
				token_type := {EIFFEL_TOKEN}.Symbol_lbrace
				advance
			when '}' then
				token_type := {EIFFEL_TOKEN}.Symbol_rbrace
				advance
			when '?' then
				advance
				if position <= source.count and then source[position] = '=' then
					text := "?="
					token_type := {EIFFEL_TOKEN}.Symbol_question_assign
					advance
				else
					token_type := {EIFFEL_TOKEN}.Token_operator
				end
			when '-' then
				advance
				if position <= source.count and then source[position] = '>' then
					text := "->"
					token_type := {EIFFEL_TOKEN}.Symbol_arrow
					advance
				else
					token_type := {EIFFEL_TOKEN}.Token_operator
				end
			when '=' then
				advance
				if position <= source.count and then source[position] = '>' then
					text := "=>"
					token_type := {EIFFEL_TOKEN}.Symbol_double_arrow
					advance
				else
					token_type := {EIFFEL_TOKEN}.Token_operator
				end
			else
				token_type := {EIFFEL_TOKEN}.Token_operator
				advance
			end

			create Result.make (token_type, text, line, start_col)
		end

feature {NONE} -- Helpers

	skip_whitespace
			-- Skip whitespace characters
		do
			from
			until
				position > source.count or else not source[position].is_space
			loop
				if source[position] = '%N' then
					line := line + 1
					column := 0
				end
				advance
			end
		end

	advance
			-- Move to next character
		do
			position := position + 1
			column := column + 1
		end

	keywords: HASH_TABLE [INTEGER, STRING]
			-- Keyword lookup table

	initialize_keywords
			-- Set up keyword table
		do
			keywords.put ({EIFFEL_TOKEN}.Keyword_class, "class")
			keywords.put ({EIFFEL_TOKEN}.Keyword_deferred, "deferred")
			keywords.put ({EIFFEL_TOKEN}.Keyword_expanded, "expanded")
			keywords.put ({EIFFEL_TOKEN}.Keyword_frozen, "frozen")
			keywords.put ({EIFFEL_TOKEN}.Keyword_inherit, "inherit")
			keywords.put ({EIFFEL_TOKEN}.Keyword_feature, "feature")
			keywords.put ({EIFFEL_TOKEN}.Keyword_create, "create")
			keywords.put ({EIFFEL_TOKEN}.Keyword_do, "do")
			keywords.put ({EIFFEL_TOKEN}.Keyword_once, "once")
			keywords.put ({EIFFEL_TOKEN}.Keyword_local, "local")
			keywords.put ({EIFFEL_TOKEN}.Keyword_require, "require")
			keywords.put ({EIFFEL_TOKEN}.Keyword_ensure, "ensure")
			keywords.put ({EIFFEL_TOKEN}.Keyword_invariant, "invariant")
			keywords.put ({EIFFEL_TOKEN}.Keyword_end, "end")
			keywords.put ({EIFFEL_TOKEN}.Keyword_if, "if")
			keywords.put ({EIFFEL_TOKEN}.Keyword_then, "then")
			keywords.put ({EIFFEL_TOKEN}.Keyword_else, "else")
			keywords.put ({EIFFEL_TOKEN}.Keyword_elseif, "elseif")
			keywords.put ({EIFFEL_TOKEN}.Keyword_from, "from")
			keywords.put ({EIFFEL_TOKEN}.Keyword_until, "until")
			keywords.put ({EIFFEL_TOKEN}.Keyword_loop, "loop")
			keywords.put ({EIFFEL_TOKEN}.Keyword_across, "across")
			keywords.put ({EIFFEL_TOKEN}.Keyword_as, "as")
			keywords.put ({EIFFEL_TOKEN}.Keyword_inspect, "inspect")
			keywords.put ({EIFFEL_TOKEN}.Keyword_when, "when")
			keywords.put ({EIFFEL_TOKEN}.Keyword_check, "check")
			keywords.put ({EIFFEL_TOKEN}.Keyword_debug, "debug")
			keywords.put ({EIFFEL_TOKEN}.Keyword_rescue, "rescue")
			keywords.put ({EIFFEL_TOKEN}.Keyword_retry, "retry")
			keywords.put ({EIFFEL_TOKEN}.Keyword_attribute, "attribute")
			keywords.put ({EIFFEL_TOKEN}.Keyword_note, "note")
			keywords.put ({EIFFEL_TOKEN}.Keyword_rename, "rename")
			keywords.put ({EIFFEL_TOKEN}.Keyword_redefine, "redefine")
			keywords.put ({EIFFEL_TOKEN}.Keyword_undefine, "undefine")
			keywords.put ({EIFFEL_TOKEN}.Keyword_select, "select")
			keywords.put ({EIFFEL_TOKEN}.Keyword_export, "export")
			keywords.put ({EIFFEL_TOKEN}.Keyword_external, "external")
			keywords.put ({EIFFEL_TOKEN}.Keyword_alias, "alias")
			keywords.put ({EIFFEL_TOKEN}.Keyword_obsolete, "obsolete")
			keywords.put ({EIFFEL_TOKEN}.Keyword_like, "like")
			keywords.put ({EIFFEL_TOKEN}.Keyword_current, "current")
			keywords.put ({EIFFEL_TOKEN}.Keyword_result, "result")
			keywords.put ({EIFFEL_TOKEN}.Keyword_precursor, "precursor")
			keywords.put ({EIFFEL_TOKEN}.Keyword_old, "old")
			keywords.put ({EIFFEL_TOKEN}.Keyword_agent, "agent")
			keywords.put ({EIFFEL_TOKEN}.Keyword_attached, "attached")
			keywords.put ({EIFFEL_TOKEN}.Keyword_detachable, "detachable")
			keywords.put ({EIFFEL_TOKEN}.Keyword_separate, "separate")
			keywords.put ({EIFFEL_TOKEN}.Keyword_and, "and")
			keywords.put ({EIFFEL_TOKEN}.Keyword_or, "or")
			keywords.put ({EIFFEL_TOKEN}.Keyword_xor, "xor")
			keywords.put ({EIFFEL_TOKEN}.Keyword_not, "not")
			keywords.put ({EIFFEL_TOKEN}.Keyword_implies, "implies")
			keywords.put ({EIFFEL_TOKEN}.Keyword_true, "true")
			keywords.put ({EIFFEL_TOKEN}.Keyword_false, "false")
			keywords.put ({EIFFEL_TOKEN}.Keyword_void, "void")
			keywords.put ({EIFFEL_TOKEN}.Keyword_convert, "convert")
			keywords.put ({EIFFEL_TOKEN}.Keyword_assign, "assign")
		end

invariant
	source_exists: source /= Void
	position_valid: position >= 1
	line_valid: line >= 1
	column_valid: column >= 1

end
