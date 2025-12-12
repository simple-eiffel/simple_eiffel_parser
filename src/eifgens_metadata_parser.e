note
	description: "[
		Parses compiled metadata from EIFGENs folder for rich semantic info.

		After ISE EiffelStudio compiles a system, it generates C source files
		containing metadata about classes, inheritance, and features. This class
		parses those files to provide accurate semantic information.

		Key files parsed:
		- evisib.c: Class name table (type_key array)
		- eparents.c: Inheritance hierarchy (ptfN arrays)
		- enames.c: Feature names per class (namesN arrays)

		Usage:
			parser := create {EIFGENS_METADATA_PARSER}.make_with_path (eifgens_w_code_path)
			parser.load
			if parser.has_class ("SIMPLE_JSON") then
				chain := parser.ancestor_chain ("SIMPLE_JSON")
				features := parser.all_inherited_features ("SIMPLE_JSON")
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFGENS_METADATA_PARSER

inherit
	ANY
		redefine
			default_create
		end

create
	default_create,
	make_with_path

feature {NONE} -- Initialization

	default_create
			-- Create parser without path
		do
			create classes.make (500)
			create class_by_index.make (500)
			create class_parents.make (500)
			create feature_names.make (500)
			eifgens_path := ""
			is_loaded := False
		end

	make_with_path (a_eifgens_path: STRING)
			-- Create parser for given EIFGENs W_code path
		require
			path_not_empty: not a_eifgens_path.is_empty
		do
			default_create
			eifgens_path := a_eifgens_path
		ensure
			path_set: eifgens_path.is_equal (a_eifgens_path)
		end

feature -- Access

	eifgens_path: STRING
			-- Path to EIFGENs/target/W_code folder

	is_loaded: BOOLEAN
			-- Has metadata been loaded successfully?

	classes: HASH_TABLE [INTEGER, STRING]
			-- Class name -> type index mapping

	class_by_index: HASH_TABLE [STRING, INTEGER]
			-- Type index -> class name mapping

	class_parents: HASH_TABLE [ARRAYED_LIST [INTEGER], INTEGER]
			-- Type index -> parent type indices mapping

	feature_names: HASH_TABLE [ARRAYED_LIST [STRING], INTEGER]
			-- Type index -> feature names mapping

feature -- Queries

	has_class (a_name: STRING): BOOLEAN
			-- Is class known from compiled metadata?
		require
			is_loaded: is_loaded
			name_not_empty: not a_name.is_empty
		do
			Result := classes.has (a_name.as_upper)
		end

	class_index (a_name: STRING): INTEGER
			-- Get type index for class name
		require
			is_loaded: is_loaded
			has_class: has_class (a_name)
		do
			Result := classes.item (a_name.as_upper)
		end

	class_name_at (a_index: INTEGER): detachable STRING
			-- Get class name for type index (Void if not found)
		require
			is_loaded: is_loaded
		do
			Result := class_by_index.item (a_index)
		end

	parent_indices (a_index: INTEGER): detachable ARRAYED_LIST [INTEGER]
			-- Get parent type indices for class (Void if not found)
		require
			is_loaded: is_loaded
		do
			Result := class_parents.item (a_index)
		end

	features_for_class (a_index: INTEGER): detachable ARRAYED_LIST [STRING]
			-- Get feature names for class (Void if not found)
		require
			is_loaded: is_loaded
		do
			Result := feature_names.item (a_index)
		end

	ancestor_chain (a_class_name: STRING): ARRAYED_LIST [STRING]
			-- Get full inheritance chain for class (breadth-first, including self)
		require
			is_loaded: is_loaded
			name_not_empty: not a_class_name.is_empty
		local
			l_index: INTEGER
			l_parents: detachable ARRAYED_LIST [INTEGER]
			l_queue: ARRAYED_QUEUE [INTEGER]
			l_visited: HASH_TABLE [BOOLEAN, INTEGER]
		do
			create Result.make (10)
			create l_queue.make (10)
			create l_visited.make (20)

			if has_class (a_class_name) then
				l_index := class_index (a_class_name)
				l_queue.extend (l_index)

				from
				until
					l_queue.is_empty
				loop
					l_index := l_queue.item
					l_queue.remove

					if not l_visited.has (l_index) then
						l_visited.force (True, l_index)
						if attached class_name_at (l_index) as l_name then
							Result.extend (l_name)
						end

						l_parents := parent_indices (l_index)
						if attached l_parents then
							across l_parents as p loop
								if p >= 0 and not l_visited.has (p) then
									l_queue.extend (p)
								end
							end
						end
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

	all_inherited_features (a_class_name: STRING): ARRAYED_LIST [STRING]
			-- Get all features (own + inherited) for class, deduped
		require
			is_loaded: is_loaded
			name_not_empty: not a_class_name.is_empty
		local
			l_chain: ARRAYED_LIST [STRING]
			l_seen: HASH_TABLE [BOOLEAN, STRING]
		do
			create Result.make (50)
			create l_seen.make (100)
			l_chain := ancestor_chain (a_class_name)

			across l_chain as c loop
				if has_class (c) then
					if attached features_for_class (class_index (c)) as l_feats then
						across l_feats as f loop
							if not l_seen.has (f) then
								l_seen.force (True, f)
								Result.extend (f)
							end
						end
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

feature -- Loading

	load
			-- Load metadata from EIFGENs path
		require
			path_set: not eifgens_path.is_empty
		local
			l_e1_path: STRING
		do
			l_e1_path := eifgens_path + "/E1"

			-- Parse eparents.c first - it has authoritative class names AND type indices
			parse_eparents (l_e1_path + "/eparents.c")

			-- Parse enames.c for feature names
			parse_enames (l_e1_path + "/enames.c")

			is_loaded := True
		ensure
			loaded: is_loaded
		end

	load_from_project (a_project_path: STRING): BOOLEAN
			-- Load from project path (auto-finds EIFGENs), returns success
		require
			path_not_empty: not a_project_path.is_empty
		local
			l_file: SIMPLE_FILE
			l_targets: ARRAYED_LIST [STRING_32]
			l_target: STRING_32
		do
			Result := False
			create l_file.make (a_project_path + "/EIFGENs")

			if l_file.is_directory then
				l_targets := l_file.directories

				-- Find a target with W_code/E1
				across l_targets as t until Result loop
					l_target := t
					create l_file.make (a_project_path + "/EIFGENs/" + l_target.to_string_8 + "/W_code/E1")
					if l_file.is_directory then
						eifgens_path := a_project_path + "/EIFGENs/" + l_target.to_string_8 + "/W_code"
						load
						Result := True
					end
				end
			end
		ensure
			loaded_on_success: Result implies is_loaded
		end

feature {NONE} -- Parsing

	parse_evisib (a_path: STRING)
			-- Parse evisib.c for class name table
		local
			l_file: SIMPLE_FILE
			l_content: STRING
			l_lines: LIST [STRING]
			l_in_array: BOOLEAN
			l_index: INTEGER
			l_line: STRING
			l_name: STRING
		do
			create l_file.make (a_path)
			if l_file.exists then
				l_content := l_file.load.to_string_8
				l_lines := l_content.split ('%N')
				l_in_array := False
				l_index := 0

				across l_lines as ln loop
					l_line := ln.twin
					l_line.left_adjust
					l_line.right_adjust

					if l_line.has_substring ("type_key []") then
						l_in_array := True
					elseif l_in_array then
						if l_line.starts_with ("}") then
							l_in_array := False
						elseif l_line.starts_with ("%"") then
							-- Extract class name: "CLASS_NAME",
							l_name := extract_quoted_string (l_line)
							if not l_name.is_empty then
								classes.force (l_index, l_name)
								class_by_index.force (l_name, l_index)
							end
							l_index := l_index + 1
						elseif l_line.starts_with ("(char *)") then
							-- Null entry - just increment index
							l_index := l_index + 1
						end
					end
				end
			end
		end

	parse_eparents (a_path: STRING)
			-- Parse eparents.c for class names, type indices, and inheritance hierarchy
			-- This is the authoritative source for class -> type index mapping
		local
			l_file: SIMPLE_FILE
			l_content: STRING
			l_lines: LIST [STRING]
			l_line: STRING
			l_class_name: STRING
			l_type_index: INTEGER
			l_pending_parents: detachable ARRAYED_LIST [INTEGER]
		do
			create l_file.make (a_path)
			if l_file.exists then
				l_content := l_file.load.to_string_8
				l_lines := l_content.split ('%N')
				l_class_name := ""
				l_pending_parents := Void

				across l_lines as ln loop
					l_line := ln.twin
					l_line.left_adjust

					-- Look for class comment: /* CLASS_NAME */
					if l_line.starts_with ("/*") and l_line.has_substring ("*/") then
						l_class_name := extract_class_comment (l_line)
						l_pending_parents := Void

					-- Look for parent array: static EIF_TYPE_INDEX ptfN[] = {parents};
					elseif l_line.has_substring ("ptf") and l_line.has_substring ("[] =") then
						l_pending_parents := extract_parent_indices (l_line)

					-- Look for type index: static struct eif_par_types parN = {N, ...};
					elseif l_line.has_substring ("eif_par_types") and l_line.has_substring ("par") then
						l_type_index := extract_type_index (l_line)
						if l_type_index >= 0 and not l_class_name.is_empty then
							-- Register the class with its actual type index
							classes.force (l_type_index, l_class_name)
							class_by_index.force (l_class_name, l_type_index)
							-- Store parents
							if attached l_pending_parents as lp then
								class_parents.force (lp, l_type_index)
							end
						end
					end
				end
			end
		end

	parse_enames (a_path: STRING)
			-- Parse enames.c for feature names per class
		local
			l_file: SIMPLE_FILE
			l_content: STRING
			l_lines: LIST [STRING]
			l_line: STRING
			l_current_class: INTEGER
			l_in_names: BOOLEAN
			l_features: ARRAYED_LIST [STRING]
			l_name: STRING
		do
			create l_file.make (a_path)
			if l_file.exists then
				l_content := l_file.load.to_string_8
				l_lines := l_content.split ('%N')
				l_current_class := -1
				l_in_names := False
				create l_features.make (20)

				across l_lines as ln loop
					l_line := ln.twin
					l_line.left_adjust
					l_line.right_adjust

					-- Look for names array start: char *namesN [] =
					if l_line.has_substring ("names") and l_line.has_substring ("[] =") then
						l_current_class := extract_names_index (l_line)
						l_in_names := False
					elseif l_line.starts_with ("{") and l_current_class >= 0 then
						l_in_names := True
						create l_features.make (20)
					elseif l_in_names then
						if l_line.starts_with ("}") then
							feature_names.force (l_features, l_current_class)
							l_in_names := False
							l_current_class := -1
						elseif l_line.starts_with ("%"") then
							l_name := extract_quoted_string (l_line)
							if not l_name.is_empty then
								l_features.extend (l_name)
							end
						end
					end
				end
			end
		end

feature {NONE} -- Extraction helpers

	extract_quoted_string (a_line: STRING): STRING
			-- Extract string between double quotes
		local
			l_start, l_end: INTEGER
		do
			Result := ""
			l_start := a_line.index_of ('"', 1)
			if l_start > 0 then
				l_end := a_line.index_of ('"', l_start + 1)
				if l_end > l_start + 1 then
					Result := a_line.substring (l_start + 1, l_end - 1)
				end
			end
		ensure
			result_exists: Result /= Void
		end

	extract_class_comment (a_line: STRING): STRING
			-- Extract class name from /* CLASS_NAME */ comment
		local
			l_start, l_end: INTEGER
		do
			Result := ""
			l_start := a_line.index_of ('*', 1)
			if l_start > 0 then
				l_end := a_line.index_of ('*', l_start + 1)
				if l_end > l_start + 1 then
					Result := a_line.substring (l_start + 1, l_end - 1)
					Result.left_adjust
					Result.right_adjust
				end
			end
		ensure
			result_exists: Result /= Void
		end

	extract_parent_indices (a_line: STRING): ARRAYED_LIST [INTEGER]
			-- Extract parent indices from ptfN[] = {i1,i2,...,0xFFFF};
		local
			l_start, l_end: INTEGER
			l_content: STRING
			l_parts: LIST [STRING]
			l_part: STRING
			l_val: INTEGER
		do
			create Result.make (5)
			l_start := a_line.index_of ('{', 1)
			l_end := a_line.index_of ('}', 1)
			if l_start > 0 and l_end > l_start then
				l_content := a_line.substring (l_start + 1, l_end - 1)
				l_parts := l_content.split (',')
				across l_parts as p loop
					l_part := p.twin
					l_part.left_adjust
					l_part.right_adjust
					if l_part.is_integer then
						l_val := l_part.to_integer
						if l_val >= 0 and l_val /= 0xFFFF then
							Result.extend (l_val)
						end
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

	extract_type_index (a_line: STRING): INTEGER
			-- Extract type index from static struct eif_par_types parN = {N, ...};
			-- The first number in the {} is the type index
		local
			l_start, l_end: INTEGER
			l_content: STRING
		do
			Result := -1
			l_start := a_line.index_of ('{', 1)
			l_end := a_line.index_of (',', l_start)
			if l_start > 0 and l_end > l_start then
				l_content := a_line.substring (l_start + 1, l_end - 1)
				l_content.left_adjust
				l_content.right_adjust
				if l_content.is_integer then
					Result := l_content.to_integer
				end
			end
		end

	extract_names_index (a_line: STRING): INTEGER
			-- Extract class index from char *namesN [] =
		local
			l_start, l_end: INTEGER
			l_num: STRING
		do
			Result := -1
			l_start := a_line.substring_index ("names", 1)
			if l_start > 0 then
				l_start := l_start + 5 -- skip "names"
				l_end := a_line.index_of (' ', l_start)
				if l_end > l_start then
					l_num := a_line.substring (l_start, l_end - 1)
					if l_num.is_integer then
						Result := l_num.to_integer
					end
				end
			end
		end

feature -- Statistics

	class_count: INTEGER
			-- Number of classes loaded
		do
			Result := classes.count
		end

	total_features: INTEGER
			-- Total feature names loaded across all classes
		do
			across feature_names as fn loop
				Result := Result + fn.count
			end
		end

invariant
	classes_exist: classes /= Void
	class_by_index_exist: class_by_index /= Void
	class_parents_exist: class_parents /= Void
	feature_names_exist: feature_names /= Void

end
