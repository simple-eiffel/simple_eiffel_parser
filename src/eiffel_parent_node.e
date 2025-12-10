note
	description: "AST node for parent class in inheritance"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_PARENT_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING)
			-- Create parent node
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			parent_name := a_name
			create renames.make (5)
			create redefines.make (5)
			create undefines.make (5)
			create selects.make (5)
		ensure
			name_set: parent_name = a_name
		end

feature -- Access

	parent_name: STRING
			-- Name of parent class

	renames: HASH_TABLE [STRING, STRING]
			-- Rename mappings: new_name -> old_name

	redefines: ARRAYED_LIST [STRING]
			-- Features being redefined

	undefines: ARRAYED_LIST [STRING]
			-- Features being undefined

	selects: ARRAYED_LIST [STRING]
			-- Features being selected

feature -- Modification

	add_rename (a_old_name, a_new_name: STRING)
			-- Add a rename clause
		require
			old_not_empty: a_old_name /= Void and then not a_old_name.is_empty
			new_not_empty: a_new_name /= Void and then not a_new_name.is_empty
		do
			renames.put (a_old_name, a_new_name)
		end

	add_redefine (a_name: STRING)
			-- Add a feature to redefine list
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			redefines.extend (a_name)
		end

	add_undefine (a_name: STRING)
			-- Add a feature to undefine list
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			undefines.extend (a_name)
		end

	add_select (a_name: STRING)
			-- Add a feature to select list
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			selects.extend (a_name)
		end

invariant
	name_not_empty: parent_name /= Void and then not parent_name.is_empty
	renames_exist: renames /= Void
	redefines_exist: redefines /= Void
	undefines_exist: undefines /= Void
	selects_exist: selects /= Void

end
