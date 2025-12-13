note
	description: "Parser for Eiffel source code - extracts classes, features, inheritance"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser
		do
			create lexer.make ("")
			create tokens.make (100)
			create last_ast.make
			token_index := 1
		end

feature -- Access

	last_ast: EIFFEL_AST
			-- Result of last parse

feature -- Parsing

	parse_string (a_source: STRING): EIFFEL_AST
			-- Parse Eiffel source code string
		require
			source_not_void: a_source /= Void
		do
			create lexer.make (a_source)
			tokens := lexer.all_tokens
			token_index := 1
			create last_ast.make

			from
			until
				is_at_end
			loop
				if current_token.token_type = {EIFFEL_TOKEN}.Keyword_class or
				   current_token.token_type = {EIFFEL_TOKEN}.Keyword_deferred or
				   current_token.token_type = {EIFFEL_TOKEN}.Keyword_expanded or
				   current_token.token_type = {EIFFEL_TOKEN}.Keyword_frozen or
				   current_token.token_type = {EIFFEL_TOKEN}.Keyword_note then
					parse_class
				else
					advance_token
				end
			end

			Result := last_ast
		ensure
			result_not_void: Result /= Void
		end

	parse_file (a_path: STRING): EIFFEL_AST
			-- Parse Eiffel file
		require
			path_not_empty: a_path /= Void and then not a_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING
		do
			create l_content.make (10000)
			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_content := l_file.last_string
				l_file.close
				Result := parse_string (l_content)
			else
				create Result.make
				Result.add_error (create {EIFFEL_PARSE_ERROR}.make ("Cannot read file: " + a_path, 1, 1))
			end
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Class Parsing

	parse_class
			-- Parse a class declaration
		local
			l_class: EIFFEL_CLASS_NODE
			l_name: STRING
			l_is_deferred, l_is_expanded, l_is_frozen: BOOLEAN
		do
			-- Handle note clause before class
			if match ({EIFFEL_TOKEN}.Keyword_note) then
				skip_note_clause
			end

			-- Handle class modifiers
			if match ({EIFFEL_TOKEN}.Keyword_deferred) then
				l_is_deferred := True
			end
			if match ({EIFFEL_TOKEN}.Keyword_expanded) then
				l_is_expanded := True
			end
			if match ({EIFFEL_TOKEN}.Keyword_frozen) then
				l_is_frozen := True
			end

			-- Expect 'class' keyword
			if match ({EIFFEL_TOKEN}.Keyword_class) then
				-- Get class name
				if check_type ({EIFFEL_TOKEN}.Token_identifier) then
					l_name := current_token.text
					create l_class.make (l_name, current_token.line, current_token.column)
					l_class.set_deferred (l_is_deferred)
					l_class.set_expanded (l_is_expanded)
					l_class.set_frozen (l_is_frozen)
					advance_token

					-- Skip generic parameters if present
					if check_type ({EIFFEL_TOKEN}.Symbol_lbracket) then
						skip_generics
					end

					-- Parse obsolete clause
					if match ({EIFFEL_TOKEN}.Keyword_obsolete) then
						skip_string
					end

					-- Parse inherit clause
					if match ({EIFFEL_TOKEN}.Keyword_inherit) then
						parse_inherit_clause (l_class)
					end

					-- Parse create clause
					if match ({EIFFEL_TOKEN}.Keyword_create) then
						parse_create_clause (l_class)
					end

					-- Parse convert clause
					if match ({EIFFEL_TOKEN}.Keyword_convert) then
						skip_convert_clause
					end

					-- Parse feature clauses
					from
					until
						is_at_end or else check_type ({EIFFEL_TOKEN}.Keyword_invariant) or else check_type ({EIFFEL_TOKEN}.Keyword_end) or else check_type ({EIFFEL_TOKEN}.Keyword_note)
					loop
						if match ({EIFFEL_TOKEN}.Keyword_feature) then
							parse_feature_clause (l_class)
						else
							advance_token
						end
					end

					-- Parse invariant
					if match ({EIFFEL_TOKEN}.Keyword_invariant) then
						skip_invariant
					end

					-- Skip trailing note
					if match ({EIFFEL_TOKEN}.Keyword_note) then
						skip_note_clause
					end

					-- Expect 'end'
					if not match ({EIFFEL_TOKEN}.Keyword_end) then
						last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Expected 'end' to close class", current_token.line, current_token.column))
					end

					last_ast.add_class (l_class)
				else
					last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Expected class name", current_token.line, current_token.column))
					advance_token
				end
			end
		end

	parse_inherit_clause (a_class: EIFFEL_CLASS_NODE)
			-- Parse inheritance clause
		local
			l_parent: EIFFEL_PARENT_NODE
			l_parent_name: STRING
		do
			from
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				l_parent_name := current_token.text
				create l_parent.make (l_parent_name)
				advance_token

				-- Skip generic parameters
				if check_type ({EIFFEL_TOKEN}.Symbol_lbracket) then
					skip_generics
				end

				-- Parse adaptation clauses
				parse_adaptation_clauses (l_parent)

				a_class.add_parent (l_parent)

				-- Handle multiple parents - check for another parent or next clause
				if check_type ({EIFFEL_TOKEN}.Keyword_create) or
				   check_type ({EIFFEL_TOKEN}.Keyword_convert) or
				   check_type ({EIFFEL_TOKEN}.Keyword_feature) or
				   check_type ({EIFFEL_TOKEN}.Keyword_invariant) or
				   check_type ({EIFFEL_TOKEN}.Keyword_end) then
					-- Exit loop - next section
				end
			end
		end

	parse_adaptation_clauses (a_parent: EIFFEL_PARENT_NODE)
			-- Parse rename, redefine, undefine, select, export
		do
			if match ({EIFFEL_TOKEN}.Keyword_rename) then
				parse_rename_clause (a_parent)
			end
			if match ({EIFFEL_TOKEN}.Keyword_export) then
				skip_export_clause
			end
			if match ({EIFFEL_TOKEN}.Keyword_undefine) then
				parse_feature_list (agent a_parent.add_undefine)
			end
			if match ({EIFFEL_TOKEN}.Keyword_redefine) then
				parse_feature_list (agent a_parent.add_redefine)
			end
			if match ({EIFFEL_TOKEN}.Keyword_select) then
				parse_feature_list (agent a_parent.add_select)
			end
			-- Skip 'end' if present (closes adaptation)
			consume ({EIFFEL_TOKEN}.Keyword_end)
		end

	parse_rename_clause (a_parent: EIFFEL_PARENT_NODE)
			-- Parse rename old_name as new_name, ...
		local
			l_old_name, l_new_name: STRING
		do
			from
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				l_old_name := current_token.text
				advance_token
				if match ({EIFFEL_TOKEN}.Keyword_as) then
					if check_type ({EIFFEL_TOKEN}.Token_identifier) then
						l_new_name := current_token.text
						advance_token
						a_parent.add_rename (l_old_name, l_new_name)
					end
				end
				consume ({EIFFEL_TOKEN}.Symbol_comma)
			end
		end

	parse_feature_list (a_action: PROCEDURE [STRING])
			-- Parse comma-separated feature list
		do
			from
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				a_action.call ([current_token.text])
				advance_token
				if not match ({EIFFEL_TOKEN}.Symbol_comma) then
					-- Check if next token starts a new clause
					if check_type ({EIFFEL_TOKEN}.Keyword_redefine) or
					   check_type ({EIFFEL_TOKEN}.Keyword_undefine) or
					   check_type ({EIFFEL_TOKEN}.Keyword_select) or
					   check_type ({EIFFEL_TOKEN}.Keyword_export) or
					   check_type ({EIFFEL_TOKEN}.Keyword_end) or
					   check_type ({EIFFEL_TOKEN}.Token_identifier) then
						-- Exit - next clause or next parent
					end
				end
			end
		end

	parse_create_clause (a_class: EIFFEL_CLASS_NODE)
			-- Parse creation clause
		do
			-- Skip export specifier
			if check_type ({EIFFEL_TOKEN}.Symbol_lbrace) then
				skip_export_specifier
			end
			-- Parse creator names
			from
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				a_class.add_creator (current_token.text)
				advance_token
				consume ({EIFFEL_TOKEN}.Symbol_comma)
			end
		end

	parse_feature_clause (a_class: EIFFEL_CLASS_NODE)
			-- Parse a feature clause
		local
			l_export_status: STRING
		do
			l_export_status := "ANY"

			-- Check for export specifier
			if check_type ({EIFFEL_TOKEN}.Symbol_lbrace) then
				l_export_status := parse_export_specifier
			end

			-- Parse features until next feature clause or end
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_feature) or else
				check_type ({EIFFEL_TOKEN}.Keyword_invariant) or else
				check_type ({EIFFEL_TOKEN}.Keyword_note) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				if check_type ({EIFFEL_TOKEN}.Token_identifier) then
					parse_feature (a_class, l_export_status)
				elseif check_type ({EIFFEL_TOKEN}.Token_comment) then
					advance_token
				elseif check_type ({EIFFEL_TOKEN}.Keyword_require) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_ensure) then
					-- DbC keyword at feature clause level indicates parser sync issue.
					-- Skip the assertion block silently to recover.
					advance_token -- consume require/ensure
					skip_assertion_recovery
				elseif check_type ({EIFFEL_TOKEN}.Keyword_do) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_once) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_external) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_local) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_attribute) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_rescue) then
					-- Body keyword at feature clause level - skip to recover
					advance_token
					skip_to_next_feature
				else
					-- Truly unexpected token - skip silently (don't report as error)
					advance_token
				end
			end
		end

	parse_feature (a_class: EIFFEL_CLASS_NODE; a_export: STRING)
			-- Parse a single feature
		local
			l_feature: EIFFEL_FEATURE_NODE
			l_name: STRING
			l_comment: STRING
			l_is_frozen: BOOLEAN
		do
			l_comment := ""

			-- Check for frozen
			if match ({EIFFEL_TOKEN}.Keyword_frozen) then
				l_is_frozen := True
			end

			-- Get feature name
			if check_type ({EIFFEL_TOKEN}.Token_identifier) then
				l_name := current_token.text
				create l_feature.make (l_name, current_token.line, current_token.column)
				l_feature.set_frozen (l_is_frozen)
				l_feature.set_export_status (a_export)
				advance_token

				-- Parse aliases (skip)
				if match ({EIFFEL_TOKEN}.Keyword_alias) then
					skip_string
				end

				-- Parse arguments
				if check_type ({EIFFEL_TOKEN}.Symbol_lparen) then
					parse_arguments (l_feature)
				end

				-- Parse return type
				if match ({EIFFEL_TOKEN}.Symbol_colon) then
					l_feature.set_return_type (parse_type)
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_function)
				end

				-- Parse assign clause
				if match ({EIFFEL_TOKEN}.Keyword_assign) then
					if check_type ({EIFFEL_TOKEN}.Token_identifier) then
						advance_token
					end
				end

				-- Check for comment after signature
				if check_type ({EIFFEL_TOKEN}.Token_comment) then
					l_comment := current_token.text.substring (3, current_token.text.count).twin
					l_comment.left_adjust
					l_feature.set_header_comment (l_comment)
					advance_token
				end

				-- Parse is/obsolete
				if match ({EIFFEL_TOKEN}.Keyword_obsolete) then
					skip_string
				end

				-- Parse require clause
				if match ({EIFFEL_TOKEN}.Keyword_require) then
					l_feature.set_precondition (parse_assertion_text)
				end

				-- Parse body
				if match ({EIFFEL_TOKEN}.Keyword_local) then
					parse_locals (l_feature)
				end

				if match ({EIFFEL_TOKEN}.Keyword_attribute) then
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
					-- Skip to end
					skip_to_feature_end
				elseif match ({EIFFEL_TOKEN}.Keyword_do) then
					if l_feature.return_type = Void then
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_procedure)
					end
					skip_compound
				elseif match ({EIFFEL_TOKEN}.Keyword_once) then
					if l_feature.return_type = Void then
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_once_procedure)
					else
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_once_function)
					end
					-- Skip once keys if present
					if check_type ({EIFFEL_TOKEN}.Symbol_lparen) then
						skip_balanced ({EIFFEL_TOKEN}.Symbol_lparen, {EIFFEL_TOKEN}.Symbol_rparen)
					end
					skip_compound
				elseif match ({EIFFEL_TOKEN}.Keyword_deferred) then
					l_feature.set_deferred (True)
				elseif match ({EIFFEL_TOKEN}.Keyword_external) then
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_external)
					skip_external
				else
					-- No body keywords - check if this is a valid attribute or incomplete feature
					if l_feature.return_type /= Void then
						-- Has type declaration (e.g., "name: TYPE") - valid attribute
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
					else
						-- No type AND no body = incomplete feature declaration
						-- A bare identifier like "asdfghjkl" without ": TYPE" or "do...end" is invalid
						last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make (
							"Incomplete feature declaration '" + l_name +
							"': expected ':' followed by type, or body keyword (do/once/deferred/external)",
							l_feature.line, l_feature.column))
						-- Add as attribute for error recovery, but error is reported
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
					end
				end

				-- Parse rescue
				if match ({EIFFEL_TOKEN}.Keyword_rescue) then
					skip_compound
				end

				-- Parse ensure clause
				if match ({EIFFEL_TOKEN}.Keyword_ensure) then
					l_feature.set_postcondition (parse_assertion_text)
				end

				-- Expect 'end' for non-attribute features with body
				if l_feature.kind /= {EIFFEL_FEATURE_NODE}.Kind_attribute or l_feature.is_deferred then
					consume ({EIFFEL_TOKEN}.Keyword_end)
				end

				a_class.add_feature (l_feature)
			end
		end

	parse_arguments (a_feature: EIFFEL_FEATURE_NODE)
			-- Parse feature arguments
		local
			l_names: ARRAYED_LIST [STRING]
			l_type: STRING
			l_pos: INTEGER
		do
			consume ({EIFFEL_TOKEN}.Symbol_lparen)
			create l_names.make (3)
			l_pos := 1

			from
			until
				is_at_end or else check_type ({EIFFEL_TOKEN}.Symbol_rparen)
			loop
				-- Collect names before colon
				if check_type ({EIFFEL_TOKEN}.Token_identifier) then
					l_names.extend (current_token.text)
					advance_token
					if match ({EIFFEL_TOKEN}.Symbol_comma) then
						-- More names
					elseif match ({EIFFEL_TOKEN}.Symbol_colon) then
						-- Type follows
						l_type := parse_type
						across l_names as n loop
							a_feature.add_argument (create {EIFFEL_ARGUMENT_NODE}.make (n, l_type, l_pos))
							l_pos := l_pos + 1
						end
						l_names.wipe_out
						consume ({EIFFEL_TOKEN}.Symbol_semicolon)
					end
				else
					advance_token
				end
			end

			consume ({EIFFEL_TOKEN}.Symbol_rparen)
		end

	parse_locals (a_feature: EIFFEL_FEATURE_NODE)
			-- Parse local variable declarations
		local
			l_names: ARRAYED_LIST [STRING]
			l_type: STRING
			l_line: INTEGER
		do
			create l_names.make (3)

			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_do) or else
				check_type ({EIFFEL_TOKEN}.Keyword_once) or else
				check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				check_type ({EIFFEL_TOKEN}.Keyword_external) or else
				check_type ({EIFFEL_TOKEN}.Keyword_attribute)
			loop
				if check_type ({EIFFEL_TOKEN}.Token_identifier) then
					l_line := current_token.line
					l_names.extend (current_token.text)
					advance_token
					if match ({EIFFEL_TOKEN}.Symbol_comma) then
						-- More names
					elseif match ({EIFFEL_TOKEN}.Symbol_colon) then
						l_type := parse_type
						across l_names as n loop
							a_feature.add_local (create {EIFFEL_LOCAL_NODE}.make (n, l_type, l_line))
						end
						l_names.wipe_out
					end
				elseif check_type ({EIFFEL_TOKEN}.Token_comment) then
					advance_token
				else
					advance_token
				end
			end
		end

	parse_type: STRING
			-- Parse a type and return as string
		do
			create Result.make (30)

			-- Handle attached/detachable
			if match ({EIFFEL_TOKEN}.Keyword_attached) then
				Result.append ("attached ")
			elseif match ({EIFFEL_TOKEN}.Keyword_detachable) then
				Result.append ("detachable ")
			end

			-- Handle separate
			if match ({EIFFEL_TOKEN}.Keyword_separate) then
				Result.append ("separate ")
			end

			-- Handle like Current/identifier
			if match ({EIFFEL_TOKEN}.Keyword_like) then
				Result.append ("like ")
				if check_type ({EIFFEL_TOKEN}.Keyword_current) then
					Result.append ("Current")
					advance_token
				elseif check_type ({EIFFEL_TOKEN}.Token_identifier) then
					Result.append (current_token.text)
					advance_token
				end
			elseif check_type ({EIFFEL_TOKEN}.Token_identifier) then
				Result.append (current_token.text)
				advance_token

				-- Handle generic parameters
				if check_type ({EIFFEL_TOKEN}.Symbol_lbracket) then
					Result.append (" [")
					advance_token
					Result.append (parse_generic_params)
					Result.append ("]")
					consume ({EIFFEL_TOKEN}.Symbol_rbracket)
				end
			end
		end

	parse_generic_params: STRING
			-- Parse generic parameters
		local
			l_depth: INTEGER
		do
			create Result.make (50)
			l_depth := 1

			from
			until
				is_at_end or else l_depth = 0
			loop
				if check_type ({EIFFEL_TOKEN}.Symbol_lbracket) then
					Result.append ("[")
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Symbol_rbracket) then
					l_depth := l_depth - 1
					if l_depth > 0 then
						Result.append ("]")
					end
				else
					Result.append (current_token.text)
				end
				if l_depth > 0 then
					advance_token
				end
			end
		end

	parse_export_specifier: STRING
			-- Parse {CLASS_LIST} and return as string
		do
			create Result.make (20)
			consume ({EIFFEL_TOKEN}.Symbol_lbrace)
			from
			until
				is_at_end or else check_type ({EIFFEL_TOKEN}.Symbol_rbrace)
			loop
				if check_type ({EIFFEL_TOKEN}.Token_identifier) then
					if not Result.is_empty then
						Result.append (", ")
					end
					Result.append (current_token.text)
				end
				advance_token
			end
			consume ({EIFFEL_TOKEN}.Symbol_rbrace)
			if Result.is_empty then
				Result := "NONE"
			end
		end

	parse_assertion_text: STRING
			-- Parse assertion clauses until next keyword, return as text
		do
			create Result.make (100)
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_local) or else
				check_type ({EIFFEL_TOKEN}.Keyword_do) or else
				check_type ({EIFFEL_TOKEN}.Keyword_once) or else
				check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				check_type ({EIFFEL_TOKEN}.Keyword_external) or else
				check_type ({EIFFEL_TOKEN}.Keyword_attribute) or else
				check_type ({EIFFEL_TOKEN}.Keyword_rescue) or else
				check_type ({EIFFEL_TOKEN}.Keyword_ensure) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				if not Result.is_empty and not check_type ({EIFFEL_TOKEN}.Token_comment) then
					Result.append (" ")
				end
				if not check_type ({EIFFEL_TOKEN}.Token_comment) then
					Result.append (current_token.text)
				end
				advance_token
			end
			Result.left_adjust
			Result.right_adjust
		end

feature {NONE} -- Skip Helpers

	skip_note_clause
			-- Skip note clause until next major section
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_class) or else
				check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				check_type ({EIFFEL_TOKEN}.Keyword_expanded) or else
				check_type ({EIFFEL_TOKEN}.Keyword_frozen) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				advance_token
			end
		end

	skip_generics
			-- Skip generic parameters [....]
		do
			skip_balanced ({EIFFEL_TOKEN}.Symbol_lbracket, {EIFFEL_TOKEN}.Symbol_rbracket)
		end

	skip_string
			-- Skip a string literal
		do
			if check_type ({EIFFEL_TOKEN}.Token_string) then
				advance_token
			end
		end

	skip_export_clause
			-- Skip export clause
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_undefine) or else
				check_type ({EIFFEL_TOKEN}.Keyword_redefine) or else
				check_type ({EIFFEL_TOKEN}.Keyword_select) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end) or else
				check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				advance_token
			end
		end

	skip_convert_clause
			-- Skip convert clause
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_feature) or else
				check_type ({EIFFEL_TOKEN}.Keyword_invariant) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				advance_token
			end
		end

	skip_export_specifier
			-- Skip {CLASS_LIST}
		do
			skip_balanced ({EIFFEL_TOKEN}.Symbol_lbrace, {EIFFEL_TOKEN}.Symbol_rbrace)
		end

	skip_compound
			-- Skip compound statements
		local
			l_depth: INTEGER
		do
			l_depth := 1
			from
			until
				is_at_end or else l_depth = 0
			loop
				if check_type ({EIFFEL_TOKEN}.Keyword_if) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_inspect) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_from) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_across) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_check) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_debug) then
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_end) then
					l_depth := l_depth - 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_rescue) or else
				        check_type ({EIFFEL_TOKEN}.Keyword_ensure) then
					l_depth := l_depth - 1
				end
				if l_depth > 0 then
					advance_token
				end
			end
		end

	skip_external
			-- Skip external clause
		do
			-- Skip string
			if check_type ({EIFFEL_TOKEN}.Token_string) then
				advance_token
			end
			-- Skip alias if present
			if match ({EIFFEL_TOKEN}.Keyword_alias) then
				if check_type ({EIFFEL_TOKEN}.Token_string) then
					advance_token
				end
			end
		end

	skip_to_feature_end
			-- Skip to end of current feature
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_ensure) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end) or else
				check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				advance_token
			end
		end

	skip_invariant
			-- Skip invariant clause
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_note) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				advance_token
			end
		end

	skip_balanced (a_open, a_close: INTEGER)
			-- Skip balanced tokens
		local
			l_depth: INTEGER
		do
			if check_type (a_open) then
				l_depth := 1
				advance_token
				from
				until
					is_at_end or else l_depth = 0
				loop
					if check_type (a_open) then
						l_depth := l_depth + 1
					elseif check_type (a_close) then
						l_depth := l_depth - 1
					end
					advance_token
				end
			end
		end

	skip_assertion_recovery
			-- Skip tokens until we reach a feature body keyword or next feature.
			-- Used to recover when require/ensure appears at unexpected location.
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Token_identifier) or else
				check_type ({EIFFEL_TOKEN}.Keyword_do) or else
				check_type ({EIFFEL_TOKEN}.Keyword_once) or else
				check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				check_type ({EIFFEL_TOKEN}.Keyword_external) or else
				check_type ({EIFFEL_TOKEN}.Keyword_local) or else
				check_type ({EIFFEL_TOKEN}.Keyword_attribute) or else
				check_type ({EIFFEL_TOKEN}.Keyword_feature) or else
				check_type ({EIFFEL_TOKEN}.Keyword_invariant) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				advance_token
			end
		end

	skip_to_next_feature
			-- Skip tokens until we reach the next feature (identifier at start of line)
			-- or a section-ending keyword.
		local
			l_depth: INTEGER
		do
			l_depth := 0
			from
			until
				is_at_end or else
				(l_depth = 0 and then check_type ({EIFFEL_TOKEN}.Token_identifier)) or else
				check_type ({EIFFEL_TOKEN}.Keyword_feature) or else
				check_type ({EIFFEL_TOKEN}.Keyword_invariant) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				-- Track nested structures
				if check_type ({EIFFEL_TOKEN}.Keyword_if) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_inspect) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_from) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_across) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_check) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_debug) then
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_end) and then l_depth > 0 then
					l_depth := l_depth - 1
				end
				advance_token
			end
		end

feature {NONE} -- Token Access

	tokens: ARRAYED_LIST [EIFFEL_TOKEN]
			-- Token stream

	token_index: INTEGER
			-- Current position in token stream

	lexer: EIFFEL_LEXER
			-- Lexer for tokenization

	current_token: EIFFEL_TOKEN
			-- Current token
		require
			not_at_end: not is_at_end
		do
			Result := tokens[token_index]
		end

	is_at_end: BOOLEAN
			-- Are we past the last token?
		do
			Result := token_index > tokens.count
		end

	advance_token
			-- Move to next token
		do
			token_index := token_index + 1
		end

	match (a_type: INTEGER): BOOLEAN
			-- If current token matches type, advance and return True
		do
			if not is_at_end and then current_token.token_type = a_type then
				Result := True
				advance_token
			end
		end

	consume (a_type: INTEGER)
			-- If current token matches type, advance (ignore result)
		do
			if not is_at_end and then current_token.token_type = a_type then
				advance_token
			end
		end

	check_type (a_type: INTEGER): BOOLEAN
			-- Does current token match type? (does not advance)
		do
			Result := not is_at_end and then current_token.token_type = a_type
		end

	report_unexpected_token (a_context: STRING)
			-- Report current token as unexpected in given context
		require
			not_at_end: not is_at_end
		do
			last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make (
				"Unexpected token in " + a_context + ": '" + current_token.text + "'",
				current_token.line,
				current_token.column))
		end

invariant
	lexer_exists: lexer /= Void
	tokens_exist: tokens /= Void
	ast_exists: last_ast /= Void

end
