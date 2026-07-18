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

			-- Handle class modifiers (any order)
			from
			until
				not (check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
					check_type ({EIFFEL_TOKEN}.Keyword_expanded) or else
					check_type ({EIFFEL_TOKEN}.Keyword_frozen))
			loop
				if match ({EIFFEL_TOKEN}.Keyword_deferred) then
					l_is_deferred := True
				elseif match ({EIFFEL_TOKEN}.Keyword_expanded) then
					l_is_expanded := True
				elseif match ({EIFFEL_TOKEN}.Keyword_frozen) then
					l_is_frozen := True
				end
			end

			-- Expect 'class' keyword
			if match ({EIFFEL_TOKEN}.Keyword_class) then
				skip_comments
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

					-- Parse inherit clause(s), including non-conforming "inherit {NONE}"
					from
					until
						not match ({EIFFEL_TOKEN}.Keyword_inherit)
					loop
						if check_type ({EIFFEL_TOKEN}.Symbol_lbrace) then
							skip_export_specifier
						end
						parse_inherit_clause (l_class)
					end

					-- Parse create clause(s), e.g. "create make create {X} make_x"
					from
					until
						not match ({EIFFEL_TOKEN}.Keyword_create)
					loop
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
						last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Expected 'end' to close class", safe_line, safe_column))
					end

					last_ast.add_class (l_class)
				else
					last_ast.add_error (create {EIFFEL_PARSE_ERROR}.make ("Expected class name", safe_line, safe_column))
					if not is_at_end then
						advance_token
					end
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
				skip_comments
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

				-- Optional separator between parents
				consume ({EIFFEL_TOKEN}.Symbol_semicolon)
				skip_comments
			end
		end

	parse_adaptation_clauses (a_parent: EIFFEL_PARENT_NODE)
			-- Parse rename, redefine, undefine, select, export (any order)
		local
			l_any: BOOLEAN
		do
			from
			until
				not (check_type ({EIFFEL_TOKEN}.Keyword_rename) or else
					check_type ({EIFFEL_TOKEN}.Keyword_export) or else
					check_type ({EIFFEL_TOKEN}.Keyword_undefine) or else
					check_type ({EIFFEL_TOKEN}.Keyword_redefine) or else
					check_type ({EIFFEL_TOKEN}.Keyword_select))
			loop
				l_any := True
				if match ({EIFFEL_TOKEN}.Keyword_rename) then
					parse_rename_clause (a_parent)
				elseif match ({EIFFEL_TOKEN}.Keyword_export) then
					skip_export_clause
				elseif match ({EIFFEL_TOKEN}.Keyword_undefine) then
					parse_feature_list (agent a_parent.add_undefine)
				elseif match ({EIFFEL_TOKEN}.Keyword_redefine) then
					parse_feature_list (agent a_parent.add_redefine)
				elseif match ({EIFFEL_TOKEN}.Keyword_select) then
					parse_feature_list (agent a_parent.add_select)
				end
			end
			-- An adaptation part is terminated by its own 'end'.
			-- Without adaptation clauses, a following 'end' belongs to the class.
			if l_any then
				consume ({EIFFEL_TOKEN}.Keyword_end)
			end
		end

	parse_rename_clause (a_parent: EIFFEL_PARENT_NODE)
			-- Parse rename old_name as new_name, ...
		local
			l_old_name, l_new_name: STRING
		do
			from
				skip_comments
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
						-- New name may carry an alias: rename plus as plus alias "+"
						from
						until
							not match ({EIFFEL_TOKEN}.Keyword_alias)
						loop
							skip_string
							consume ({EIFFEL_TOKEN}.Keyword_convert)
						end
					end
				end
				consume ({EIFFEL_TOKEN}.Symbol_comma)
				skip_comments
			end
		end

	parse_feature_list (a_action: PROCEDURE [STRING])
			-- Parse comma-separated feature list
		do
			from
				skip_comments
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				a_action.call ([current_token.text])
				advance_token
				consume ({EIFFEL_TOKEN}.Symbol_comma)
				skip_comments
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
				skip_comments
			until
				is_at_end or else not check_type ({EIFFEL_TOKEN}.Token_identifier)
			loop
				a_class.add_creator (current_token.text)
				advance_token
				consume ({EIFFEL_TOKEN}.Symbol_comma)
				skip_comments
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
			-- Parse a single feature declaration, possibly introducing
			-- several features sharing one signature: "a, b: INTEGER".
		local
			l_feature, l_other: EIFFEL_FEATURE_NODE
			l_siblings: ARRAYED_LIST [EIFFEL_FEATURE_NODE]
			l_name: STRING
			l_comment: STRING
			l_is_frozen: BOOLEAN
			l_has_body: BOOLEAN
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

				-- Parse aliases (skip) - Eiffel allows multiple aliases per feature
				from
				until
					not match ({EIFFEL_TOKEN}.Keyword_alias)
				loop
					skip_string
					consume ({EIFFEL_TOKEN}.Keyword_convert)
				end

				-- Additional names sharing this declaration: "count, capacity: INTEGER"
				create l_siblings.make (1)
				l_siblings.extend (l_feature)
				from
				until
					not match ({EIFFEL_TOKEN}.Symbol_comma)
				loop
					skip_comments
					consume ({EIFFEL_TOKEN}.Keyword_frozen)
					if check_type ({EIFFEL_TOKEN}.Token_identifier) then
						create l_other.make (current_token.text, current_token.line, current_token.column)
						l_other.set_frozen (l_is_frozen)
						l_other.set_export_status (a_export)
						l_siblings.extend (l_other)
						advance_token
						from
						until
							not match ({EIFFEL_TOKEN}.Keyword_alias)
						loop
							skip_string
							consume ({EIFFEL_TOKEN}.Keyword_convert)
						end
					end
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

				-- Manifest constant: Name: TYPE = value
				if check_type ({EIFFEL_TOKEN}.Token_operator) and then current_token.text.same_string ("=") then
					advance_token
					if check_type ({EIFFEL_TOKEN}.Symbol_lbrace) then
						-- Typed manifest: {INTEGER_64} 100
						skip_balanced ({EIFFEL_TOKEN}.Symbol_lbrace, {EIFFEL_TOKEN}.Symbol_rbrace)
					end
					if check_type ({EIFFEL_TOKEN}.Token_operator) then
						advance_token -- sign
					end
					if not is_at_end then
						advance_token -- the literal value
					end
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
				end

				-- Header comment (possibly several lines), feature-level
				-- note and obsolete clauses, in any order
				from
				until
					not (check_type ({EIFFEL_TOKEN}.Token_comment) or else
						check_type ({EIFFEL_TOKEN}.Keyword_note) or else
						check_type ({EIFFEL_TOKEN}.Keyword_obsolete))
				loop
					if check_type ({EIFFEL_TOKEN}.Token_comment) then
						if l_comment.is_empty and then current_token.text.count > 2 then
							l_comment := current_token.text.substring (3, current_token.text.count).twin
							l_comment.left_adjust
							l_feature.set_header_comment (l_comment)
						end
						advance_token
					elseif match ({EIFFEL_TOKEN}.Keyword_note) then
						skip_feature_note
					elseif match ({EIFFEL_TOKEN}.Keyword_obsolete) then
						skip_string
					end
				end

				-- Parse require clause ("require else" for redefinitions)
				if match ({EIFFEL_TOKEN}.Keyword_require) then
					consume ({EIFFEL_TOKEN}.Keyword_else)
					l_feature.set_precondition (parse_assertion_text)
				end

				-- Parse body
				skip_comments
				if match ({EIFFEL_TOKEN}.Keyword_local) then
					parse_locals (l_feature)
				end

				skip_comments
				if match ({EIFFEL_TOKEN}.Keyword_attribute) then
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_attribute)
					l_has_body := True
					skip_compound
				elseif match ({EIFFEL_TOKEN}.Keyword_do) then
					if l_feature.return_type = Void then
						l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_procedure)
					end
					l_has_body := True
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
					l_has_body := True
					skip_compound
				elseif match ({EIFFEL_TOKEN}.Keyword_deferred) then
					l_feature.set_deferred (True)
					l_has_body := True
				elseif match ({EIFFEL_TOKEN}.Keyword_external) then
					l_feature.set_kind ({EIFFEL_FEATURE_NODE}.Kind_external)
					skip_external
					l_has_body := True
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

				-- Parse rescue and ensure ("ensure then" for redefinitions);
				-- rescue may appear before or after the postcondition
				skip_comments
				if match ({EIFFEL_TOKEN}.Keyword_rescue) then
					skip_compound
				end
				skip_comments
				if match ({EIFFEL_TOKEN}.Keyword_ensure) then
					consume ({EIFFEL_TOKEN}.Keyword_then)
					l_feature.set_postcondition (parse_assertion_text)
				end
				skip_comments
				if match ({EIFFEL_TOKEN}.Keyword_rescue) then
					skip_compound
				end

				-- Bodies (do/once/attribute/deferred/external) close with 'end';
				-- bare attributes and constants do not
				skip_comments
				if l_has_body then
					consume ({EIFFEL_TOKEN}.Keyword_end)
				end

				-- Propagate shared signature to sibling names and register all
				across l_siblings as ic_f loop
					if ic_f /= l_feature then
						ic_f.set_kind (l_feature.kind)
						if attached l_feature.return_type as al_rt then
							ic_f.set_return_type (al_rt)
						end
						across l_feature.arguments as ic_a loop
							ic_f.add_argument (ic_a)
						end
						if not l_feature.precondition.is_empty then
							ic_f.set_precondition (l_feature.precondition)
						end
						if not l_feature.postcondition.is_empty then
							ic_f.set_postcondition (l_feature.postcondition)
						end
						if not l_comment.is_empty then
							ic_f.set_header_comment (l_comment)
						end
						ic_f.set_deferred (l_feature.is_deferred)
					end
					a_class.add_feature (ic_f)
				end
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
						if not l_type.is_empty then
							across l_names as ic_n loop
								a_feature.add_argument (create {EIFFEL_ARGUMENT_NODE}.make (ic_n, l_type, l_pos))
								l_pos := l_pos + 1
							end
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
						if not l_type.is_empty then
							across l_names as ic_n loop
								a_feature.add_local (create {EIFFEL_LOCAL_NODE}.make (ic_n, l_type, l_line))
							end
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

			-- Old-style attachment marks: ?TYPE (detachable), !TYPE (attached)
			if check_type ({EIFFEL_TOKEN}.Token_operator) and then
				(current_token.text.same_string ("?") or else current_token.text.same_string ("!"))
			then
				advance_token
			end

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

			-- Handle like Current/identifier/{QUALIFIED}.anchor
			if match ({EIFFEL_TOKEN}.Keyword_like) then
				Result.append ("like ")
				if check_type ({EIFFEL_TOKEN}.Keyword_current) then
					Result.append ("Current")
					advance_token
				elseif check_type ({EIFFEL_TOKEN}.Symbol_lbrace) then
					-- Qualified anchor: like {SPECIAL [G]}.lower
					Result.append ("{")
					advance_token
					from
					until
						is_at_end or else check_type ({EIFFEL_TOKEN}.Symbol_rbrace)
					loop
						Result.append (current_token.text)
						advance_token
					end
					Result.append ("}")
					consume ({EIFFEL_TOKEN}.Symbol_rbrace)
				elseif check_type ({EIFFEL_TOKEN}.Token_identifier) then
					Result.append (current_token.text)
					advance_token
				end
				-- Dotted anchors: like area.lower
				from
				until
					not check_type ({EIFFEL_TOKEN}.Symbol_dot)
				loop
					Result.append (".")
					advance_token
					if check_type ({EIFFEL_TOKEN}.Token_identifier) then
						Result.append (current_token.text)
						advance_token
					end
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
			-- Parse assertion clauses until the next routine-section keyword.
			-- Tracks 'end'-bearing expressions (across/if/inspect) so that
			-- expression-level 'end' tokens do not terminate the assertion.
		local
			l_depth: INTEGER
			l_paren: INTEGER
		do
			create Result.make (100)
			from
			until
				is_at_end or else
				(l_depth = 0 and then l_paren = 0 and then (
					check_type ({EIFFEL_TOKEN}.Keyword_local) or else
					check_type ({EIFFEL_TOKEN}.Keyword_do) or else
					(check_type ({EIFFEL_TOKEN}.Keyword_once) and then not is_once_manifest_string) or else
					check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
					check_type ({EIFFEL_TOKEN}.Keyword_external) or else
					check_type ({EIFFEL_TOKEN}.Keyword_attribute) or else
					check_type ({EIFFEL_TOKEN}.Keyword_note) or else
					check_type ({EIFFEL_TOKEN}.Keyword_rescue) or else
					check_type ({EIFFEL_TOKEN}.Keyword_ensure) or else
					check_type ({EIFFEL_TOKEN}.Keyword_end)))
			loop
				if check_type ({EIFFEL_TOKEN}.Symbol_lparen) then
					l_paren := l_paren + 1
				elseif check_type ({EIFFEL_TOKEN}.Symbol_rparen) then
					if l_paren > 0 then
						l_paren := l_paren - 1
					end
				elseif check_type ({EIFFEL_TOKEN}.Keyword_across) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_if) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_inspect) then
					l_depth := l_depth + 1
				elseif l_paren > 0 and then
					(check_type ({EIFFEL_TOKEN}.Keyword_do) or else
					 (check_type ({EIFFEL_TOKEN}.Keyword_once) and then not is_once_manifest_string)) then
					-- Inline agent body inside a call argument
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_end) and then l_depth > 0 then
					l_depth := l_depth - 1
				end
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
			-- Skip export adaptation clause: brace groups and feature lists,
			-- e.g. "export {NONE} all {ANY} copy, is_equal"
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_rename) or else
				check_type ({EIFFEL_TOKEN}.Keyword_undefine) or else
				check_type ({EIFFEL_TOKEN}.Keyword_redefine) or else
				check_type ({EIFFEL_TOKEN}.Keyword_select) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
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
			-- Skip a routine body until its terminating 'end' (left unconsumed)
			-- or a routine-level 'ensure'/'rescue'. Tracks nested constructs
			-- including inline agent bodies (do/once ... end).
		local
			l_depth: INTEGER
			l_across_pending: INTEGER
		do
			l_depth := 1
			from
			until
				is_at_end or else l_depth = 0
			loop
				if check_type ({EIFFEL_TOKEN}.Keyword_across) then
					l_depth := l_depth + 1
					l_across_pending := l_across_pending + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_from) then
					-- 'from' inside an across header is a clause of that across,
					-- not a separate loop with its own 'end'
					if l_across_pending = 0 then
						l_depth := l_depth + 1
					end
				elseif check_type ({EIFFEL_TOKEN}.Keyword_loop) then
					l_across_pending := 0
				elseif check_type ({EIFFEL_TOKEN}.Keyword_if) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_inspect) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_check) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_debug) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_do) then
					-- 'do' here can only open an inline agent body
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_once) and then not is_once_manifest_string then
					-- inline once-agent body; 'once "..."' is a manifest string
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_end) then
					l_depth := l_depth - 1
					l_across_pending := 0
				elseif l_depth = 1 and then
					(check_type ({EIFFEL_TOKEN}.Keyword_rescue) or else
					 check_type ({EIFFEL_TOKEN}.Keyword_ensure)) then
					l_depth := 0
				end
				if l_depth > 0 then
					advance_token
				end
			end
		end

	peek_type: INTEGER
			-- Type of token after the current one (EOF if none)
		do
			if token_index + 1 <= tokens.count then
				Result := tokens [token_index + 1].token_type
			else
				Result := {EIFFEL_TOKEN}.Token_eof
			end
		end

	is_once_manifest_string: BOOLEAN
			-- Is the current 'once' token a once-string expression rather than
			-- a body opener? Covers 'once "..."' and typed 'once {STRING_32} "..."'.
		do
			Result := peek_type = {EIFFEL_TOKEN}.Token_string or else
				peek_type = {EIFFEL_TOKEN}.Symbol_lbrace
		end

	safe_line: INTEGER
			-- Line of current token, or of last token when at end (0 if no tokens)
		do
			if not is_at_end then
				Result := current_token.line
			elseif not tokens.is_empty then
				Result := tokens.last.line
			end
		end

	safe_column: INTEGER
			-- Column of current token, or of last token when at end (0 if no tokens)
		do
			if not is_at_end then
				Result := current_token.column
			elseif not tokens.is_empty then
				Result := tokens.last.column
			end
		end

	skip_comments
			-- Skip any comment tokens at the current position
		do
			from
			until
				not check_type ({EIFFEL_TOKEN}.Token_comment)
			loop
				advance_token
			end
		end

	skip_feature_note
			-- Skip a feature-level note clause (after 'note' keyword),
			-- stopping at the first routine-section keyword.
		do
			from
			until
				is_at_end or else
				check_type ({EIFFEL_TOKEN}.Keyword_require) or else
				check_type ({EIFFEL_TOKEN}.Keyword_local) or else
				check_type ({EIFFEL_TOKEN}.Keyword_do) or else
				check_type ({EIFFEL_TOKEN}.Keyword_once) or else
				check_type ({EIFFEL_TOKEN}.Keyword_deferred) or else
				check_type ({EIFFEL_TOKEN}.Keyword_external) or else
				check_type ({EIFFEL_TOKEN}.Keyword_attribute) or else
				check_type ({EIFFEL_TOKEN}.Keyword_obsolete) or else
				check_type ({EIFFEL_TOKEN}.Keyword_end)
			loop
				advance_token
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
			-- Skip invariant clause, tracking expression-level 'end' tokens
			-- (across/if/inspect expressions and inline agents inside assertions)
		local
			l_depth: INTEGER
			l_paren: INTEGER
		do
			from
			until
				is_at_end or else
				(l_depth = 0 and then l_paren = 0 and then (
					check_type ({EIFFEL_TOKEN}.Keyword_note) or else
					check_type ({EIFFEL_TOKEN}.Keyword_end)))
			loop
				if check_type ({EIFFEL_TOKEN}.Symbol_lparen) then
					l_paren := l_paren + 1
				elseif check_type ({EIFFEL_TOKEN}.Symbol_rparen) then
					if l_paren > 0 then
						l_paren := l_paren - 1
					end
				elseif check_type ({EIFFEL_TOKEN}.Keyword_across) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_if) or else
				   check_type ({EIFFEL_TOKEN}.Keyword_inspect) then
					l_depth := l_depth + 1
				elseif l_paren > 0 and then
					(check_type ({EIFFEL_TOKEN}.Keyword_do) or else
					 (check_type ({EIFFEL_TOKEN}.Keyword_once) and then not is_once_manifest_string)) then
					l_depth := l_depth + 1
				elseif check_type ({EIFFEL_TOKEN}.Keyword_end) and then l_depth > 0 then
					l_depth := l_depth - 1
				end
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
