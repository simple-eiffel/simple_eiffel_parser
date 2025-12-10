note
	description: "AST node representing an Eiffel class"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_CLASS_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING; a_line, a_column: INTEGER)
			-- Create class node
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
			line_valid: a_line >= 1
			column_valid: a_column >= 1
		do
			name := a_name
			line := a_line
			column := a_column
			create features.make (20)
			create parents.make (5)
			create creators.make (5)
			header_comment := ""
		ensure
			name_set: name = a_name
			line_set: line = a_line
			column_set: column = a_column
		end

feature -- Access

	name: STRING
			-- Class name

	line: INTEGER
			-- Line number of class declaration

	column: INTEGER
			-- Column number of class declaration

	is_deferred: BOOLEAN
			-- Is this a deferred class?

	is_expanded: BOOLEAN
			-- Is this an expanded class?

	is_frozen: BOOLEAN
			-- Is this a frozen class?

	header_comment: STRING
			-- Header comment (from note clause or first comment)

	features: ARRAYED_LIST [EIFFEL_FEATURE_NODE]
			-- Features declared in this class

	parents: ARRAYED_LIST [EIFFEL_PARENT_NODE]
			-- Parent classes

	creators: ARRAYED_LIST [STRING]
			-- Creation procedure names

feature -- Modification

	set_deferred (a_value: BOOLEAN)
			-- Set deferred flag
		do
			is_deferred := a_value
		ensure
			deferred_set: is_deferred = a_value
		end

	set_expanded (a_value: BOOLEAN)
			-- Set expanded flag
		do
			is_expanded := a_value
		ensure
			expanded_set: is_expanded = a_value
		end

	set_frozen (a_value: BOOLEAN)
			-- Set frozen flag
		do
			is_frozen := a_value
		ensure
			frozen_set: is_frozen = a_value
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

	add_feature (a_feature: EIFFEL_FEATURE_NODE)
			-- Add a feature
		require
			feature_not_void: a_feature /= Void
		do
			features.extend (a_feature)
		ensure
			feature_added: features.has (a_feature)
		end

	add_parent (a_parent: EIFFEL_PARENT_NODE)
			-- Add a parent class
		require
			parent_not_void: a_parent /= Void
		do
			parents.extend (a_parent)
		ensure
			parent_added: parents.has (a_parent)
		end

	add_creator (a_name: STRING)
			-- Add a creation procedure name
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			creators.extend (a_name)
		ensure
			creator_added: creators.has (a_name)
		end

feature -- Query

	feature_by_name (a_name: STRING): detachable EIFFEL_FEATURE_NODE
			-- Find feature by name, or Void if not found
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			across features as f loop
				if f.name.is_case_insensitive_equal (a_name) then
					Result := f
				end
			end
		end

invariant
	name_not_empty: name /= Void and then not name.is_empty
	line_valid: line >= 1
	column_valid: column >= 1
	features_exist: features /= Void
	parents_exist: parents /= Void
	creators_exist: creators /= Void

end
