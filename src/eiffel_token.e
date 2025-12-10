note
	description: "Token types and token structure for Eiffel lexer"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_TOKEN

create
	make

feature {NONE} -- Initialization

	make (a_type: like token_type; a_text: STRING; a_line, a_column: INTEGER)
			-- Create token with type, text, and position
		require
			text_not_void: a_text /= Void
			line_positive: a_line >= 1
			column_positive: a_column >= 1
		do
			token_type := a_type
			text := a_text
			line := a_line
			column := a_column
		ensure
			type_set: token_type = a_type
			text_set: text = a_text
			line_set: line = a_line
			column_set: column = a_column
		end

feature -- Access

	token_type: INTEGER
			-- Type of this token

	text: STRING
			-- Raw text of token

	line: INTEGER
			-- Line number (1-based)

	column: INTEGER
			-- Column number (1-based)

feature -- Query

	is_keyword: BOOLEAN
			-- Is this a keyword token?
		do
			Result := token_type >= Keyword_class and token_type <= Keyword_end
		end

	is_identifier: BOOLEAN
			-- Is this an identifier?
		do
			Result := token_type = Token_identifier
		end

	is_eof: BOOLEAN
			-- Is this end of file?
		do
			Result := token_type = Token_eof
		end

feature -- Token Types (Constants)

	Token_eof: INTEGER = 0
	Token_identifier: INTEGER = 1
	Token_integer: INTEGER = 2
	Token_real: INTEGER = 3
	Token_string: INTEGER = 4
	Token_character: INTEGER = 5
	Token_comment: INTEGER = 6
	Token_operator: INTEGER = 7
	Token_symbol: INTEGER = 8

	-- Keywords (100-199)
	Keyword_class: INTEGER = 100
	Keyword_deferred: INTEGER = 101
	Keyword_expanded: INTEGER = 102
	Keyword_frozen: INTEGER = 103
	Keyword_inherit: INTEGER = 104
	Keyword_feature: INTEGER = 105
	Keyword_create: INTEGER = 106
	Keyword_do: INTEGER = 107
	Keyword_once: INTEGER = 108
	Keyword_local: INTEGER = 109
	Keyword_require: INTEGER = 110
	Keyword_ensure: INTEGER = 111
	Keyword_invariant: INTEGER = 112
	Keyword_end: INTEGER = 113
	Keyword_if: INTEGER = 114
	Keyword_then: INTEGER = 115
	Keyword_else: INTEGER = 116
	Keyword_elseif: INTEGER = 117
	Keyword_from: INTEGER = 118
	Keyword_until: INTEGER = 119
	Keyword_loop: INTEGER = 120
	Keyword_across: INTEGER = 121
	Keyword_as: INTEGER = 122
	Keyword_inspect: INTEGER = 123
	Keyword_when: INTEGER = 124
	Keyword_check: INTEGER = 125
	Keyword_debug: INTEGER = 126
	Keyword_rescue: INTEGER = 127
	Keyword_retry: INTEGER = 128
	Keyword_attribute: INTEGER = 129
	Keyword_note: INTEGER = 130
	Keyword_rename: INTEGER = 131
	Keyword_redefine: INTEGER = 132
	Keyword_undefine: INTEGER = 133
	Keyword_select: INTEGER = 134
	Keyword_export: INTEGER = 135
	Keyword_external: INTEGER = 136
	Keyword_alias: INTEGER = 137
	Keyword_obsolete: INTEGER = 138
	Keyword_like: INTEGER = 139
	Keyword_current: INTEGER = 140
	Keyword_result: INTEGER = 141
	Keyword_precursor: INTEGER = 142
	Keyword_old: INTEGER = 143
	Keyword_agent: INTEGER = 144
	Keyword_attached: INTEGER = 145
	Keyword_detachable: INTEGER = 146
	Keyword_separate: INTEGER = 147
	Keyword_and: INTEGER = 148
	Keyword_or: INTEGER = 149
	Keyword_xor: INTEGER = 150
	Keyword_not: INTEGER = 151
	Keyword_implies: INTEGER = 152
	Keyword_true: INTEGER = 153
	Keyword_false: INTEGER = 154
	Keyword_void: INTEGER = 155
	Keyword_convert: INTEGER = 156
	Keyword_assign: INTEGER = 157

	-- Symbols (200-299)
	Symbol_colon: INTEGER = 200
	Symbol_semicolon: INTEGER = 201
	Symbol_comma: INTEGER = 202
	Symbol_dot: INTEGER = 203
	Symbol_lparen: INTEGER = 204
	Symbol_rparen: INTEGER = 205
	Symbol_lbracket: INTEGER = 206
	Symbol_rbracket: INTEGER = 207
	Symbol_lbrace: INTEGER = 208
	Symbol_rbrace: INTEGER = 209
	Symbol_assign: INTEGER = 210
	Symbol_question_assign: INTEGER = 211
	Symbol_arrow: INTEGER = 212
	Symbol_double_arrow: INTEGER = 213

invariant
	text_exists: text /= Void
	line_valid: line >= 1
	column_valid: column >= 1

end
