note
	description: "AST nodes for parsed Eiffel source"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_AST

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize empty AST
		do
			create classes.make (10)
			create parse_errors.make (5)
		end

feature -- Access

	classes: ARRAYED_LIST [EIFFEL_CLASS_NODE]
			-- Parsed classes

	parse_errors: ARRAYED_LIST [EIFFEL_PARSE_ERROR]
			-- Errors encountered during parsing

feature -- Modification

	add_class (a_class: EIFFEL_CLASS_NODE)
			-- Add a class to the AST
		require
			class_not_void: a_class /= Void
		do
			classes.extend (a_class)
		ensure
			class_added: classes.has (a_class)
		end

	add_error (a_error: EIFFEL_PARSE_ERROR)
			-- Add a parse error
		require
			error_not_void: a_error /= Void
		do
			parse_errors.extend (a_error)
		ensure
			error_added: parse_errors.has (a_error)
		end

feature -- Query

	has_errors: BOOLEAN
			-- Were there any parse errors?
		do
			Result := not parse_errors.is_empty
		end

invariant
	classes_exist: classes /= Void
	errors_exist: parse_errors /= Void

end
