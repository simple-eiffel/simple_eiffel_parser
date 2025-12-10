note
	description: "AST node for local variable"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_LOCAL_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name, a_type: STRING; a_line: INTEGER)
			-- Create local variable node
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
			type_not_empty: a_type /= Void and then not a_type.is_empty
			line_valid: a_line >= 1
		do
			name := a_name
			local_type := a_type
			line := a_line
		ensure
			name_set: name = a_name
			type_set: local_type = a_type
			line_set: line = a_line
		end

feature -- Access

	name: STRING
			-- Local variable name

	local_type: STRING
			-- Variable type

	line: INTEGER
			-- Line number of declaration

invariant
	name_not_empty: name /= Void and then not name.is_empty
	type_not_empty: local_type /= Void and then not local_type.is_empty
	line_valid: line >= 1

end
