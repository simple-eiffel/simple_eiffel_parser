note
	description: "AST node for feature argument"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_ARGUMENT_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name, a_type: STRING; a_position: INTEGER)
			-- Create argument node
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
			type_not_empty: a_type /= Void and then not a_type.is_empty
			position_valid: a_position >= 1
		do
			name := a_name
			arg_type := a_type
			position := a_position
		ensure
			name_set: name = a_name
			type_set: arg_type = a_type
			position_set: position = a_position
		end

feature -- Access

	name: STRING
			-- Argument name

	arg_type: STRING
			-- Argument type

	position: INTEGER
			-- Position in argument list (1-based)

invariant
	name_not_empty: name /= Void and then not name.is_empty
	type_not_empty: arg_type /= Void and then not arg_type.is_empty
	position_valid: position >= 1

end
