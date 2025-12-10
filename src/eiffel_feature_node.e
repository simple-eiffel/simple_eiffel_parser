note
	description: "AST node representing an Eiffel feature"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_FEATURE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING; a_line, a_column: INTEGER)
			-- Create feature node
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
			line_valid: a_line >= 1
			column_valid: a_column >= 1
		do
			name := a_name
			line := a_line
			column := a_column
			kind := Kind_procedure
			create arguments.make (5)
			create locals.make (5)
			export_status := "ANY"
			header_comment := ""
			precondition := ""
			postcondition := ""
		ensure
			name_set: name = a_name
			line_set: line = a_line
			column_set: column = a_column
		end

feature -- Access

	name: STRING
			-- Feature name

	line: INTEGER
			-- Line number of feature declaration

	column: INTEGER
			-- Column number of feature declaration

	kind: INTEGER
			-- Feature kind (attribute, procedure, function, once)

	return_type: detachable STRING
			-- Return type for functions, Void for procedures

	arguments: ARRAYED_LIST [EIFFEL_ARGUMENT_NODE]
			-- Feature arguments

	locals: ARRAYED_LIST [EIFFEL_LOCAL_NODE]
			-- Local variables

	precondition: STRING
			-- Require clause text

	postcondition: STRING
			-- Ensure clause text

	header_comment: STRING
			-- Feature header comment

	is_deferred: BOOLEAN
			-- Is this a deferred feature?

	is_frozen: BOOLEAN
			-- Is this a frozen feature?

	export_status: STRING
			-- Export status (ANY, NONE, or client list)

feature -- Constants

	Kind_attribute: INTEGER = 1
	Kind_procedure: INTEGER = 2
	Kind_function: INTEGER = 3
	Kind_once_function: INTEGER = 4
	Kind_once_procedure: INTEGER = 5
	Kind_external: INTEGER = 6

feature -- Modification

	set_kind (a_kind: INTEGER)
			-- Set feature kind
		do
			kind := a_kind
		ensure
			kind_set: kind = a_kind
		end

	set_return_type (a_type: STRING)
			-- Set return type
		require
			type_not_void: a_type /= Void
		do
			return_type := a_type
		ensure
			type_set: return_type = a_type
		end

	set_precondition (a_text: STRING)
			-- Set precondition text
		require
			text_not_void: a_text /= Void
		do
			precondition := a_text
		ensure
			precondition_set: precondition = a_text
		end

	set_postcondition (a_text: STRING)
			-- Set postcondition text
		require
			text_not_void: a_text /= Void
		do
			postcondition := a_text
		ensure
			postcondition_set: postcondition = a_text
		end

	set_header_comment (a_comment: STRING)
			-- Set header comment
		require
			comment_not_void: a_comment /= Void
		do
			header_comment := a_comment
		ensure
			comment_set: header_comment = a_comment
		end

	set_deferred (a_value: BOOLEAN)
			-- Set deferred flag
		do
			is_deferred := a_value
		ensure
			deferred_set: is_deferred = a_value
		end

	set_frozen (a_value: BOOLEAN)
			-- Set frozen flag
		do
			is_frozen := a_value
		ensure
			frozen_set: is_frozen = a_value
		end

	set_export_status (a_status: STRING)
			-- Set export status
		require
			status_not_void: a_status /= Void
		do
			export_status := a_status
		ensure
			export_set: export_status = a_status
		end

	add_argument (a_arg: EIFFEL_ARGUMENT_NODE)
			-- Add an argument
		require
			arg_not_void: a_arg /= Void
		do
			arguments.extend (a_arg)
		ensure
			arg_added: arguments.has (a_arg)
		end

	add_local (a_local: EIFFEL_LOCAL_NODE)
			-- Add a local variable
		require
			local_not_void: a_local /= Void
		do
			locals.extend (a_local)
		ensure
			local_added: locals.has (a_local)
		end

feature -- Query

	is_function: BOOLEAN
			-- Is this a function (has return type)?
		do
			Result := kind = Kind_function or kind = Kind_once_function
		end

	is_procedure: BOOLEAN
			-- Is this a procedure (no return type)?
		do
			Result := kind = Kind_procedure or kind = Kind_once_procedure
		end

	is_attribute: BOOLEAN
			-- Is this an attribute?
		do
			Result := kind = Kind_attribute
		end

	is_once: BOOLEAN
			-- Is this a once feature?
		do
			Result := kind = Kind_once_function or kind = Kind_once_procedure
		end

	signature: STRING
			-- Full signature as string
		local
			l_first: BOOLEAN
		do
			create Result.make (50)
			Result.append (name)
			if not arguments.is_empty then
				Result.append (" (")
				l_first := True
				across arguments as arg loop
					if not l_first then
						Result.append ("; ")
					end
					l_first := False
					Result.append (arg.name)
					Result.append (": ")
					Result.append (arg.arg_type)
				end
				Result.append (")")
			end
			if attached return_type as rt then
				Result.append (": ")
				Result.append (rt)
			end
		end

	kind_string: STRING
			-- Kind as human-readable string
		do
			inspect kind
			when Kind_attribute then
				Result := "attribute"
			when Kind_procedure then
				Result := "procedure"
			when Kind_function then
				Result := "function"
			when Kind_once_function then
				Result := "once"
			when Kind_once_procedure then
				Result := "once"
			when Kind_external then
				Result := "external"
			else
				Result := "unknown"
			end
		end

invariant
	name_not_empty: name /= Void and then not name.is_empty
	line_valid: line >= 1
	column_valid: column >= 1
	arguments_exist: arguments /= Void
	locals_exist: locals /= Void

end
