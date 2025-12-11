note
	description: "DbC metrics for a class"
	date: "$Date$"
	revision: "$Revision$"

class
	DBC_CLASS_METRICS

create
	make

feature {NONE} -- Initialization

	make (a_lib_name, a_class_name, a_file_path: STRING)
			-- Create class metrics
		require
			lib_not_empty: not a_lib_name.is_empty
			class_not_empty: not a_class_name.is_empty
		do
			library_name := a_lib_name
			class_name := a_class_name
			file_path := a_file_path
		ensure
			lib_set: library_name = a_lib_name
			class_set: class_name = a_class_name
		end

feature -- Access

	library_name: STRING
			-- Owning library

	class_name: STRING
			-- Class name

	file_path: STRING
			-- Source file path

	feature_count: INTEGER
			-- Number of features

	attribute_count: INTEGER
			-- Number of attributes

	lines_of_code: INTEGER
			-- Lines of actual code (excluding notes, comments, blanks)

	require_count: INTEGER
			-- Features with preconditions

	ensure_count: INTEGER
			-- Features with postconditions

	precondition_lines: INTEGER
			-- Individual precondition assertion lines

	postcondition_lines: INTEGER
			-- Individual postcondition assertion lines

	invariant_lines: INTEGER
			-- Individual class invariant assertion lines

	has_invariant: BOOLEAN
			-- Does class have invariant?

	score: INTEGER
			-- DbC score (0-100)

	total_contract_lines: INTEGER
			-- Total contract assertion lines
		do
			Result := precondition_lines + postcondition_lines + invariant_lines
		end

	contracts_per_feature: REAL_64
			-- Average contracts per feature
		do
			if feature_count > 0 then
				Result := total_contract_lines / feature_count
			end
		end

feature -- Modification

	increment_feature_count
		do
			feature_count := feature_count + 1
		end

	increment_require_count
		do
			require_count := require_count + 1
		end

	increment_ensure_count
		do
			ensure_count := ensure_count + 1
		end

	set_has_invariant (a_value: BOOLEAN)
		do
			has_invariant := a_value
		end

	set_attribute_count (a_value: INTEGER)
		do
			attribute_count := a_value
		end

	set_lines_of_code (a_value: INTEGER)
		do
			lines_of_code := a_value
		end

	set_precondition_lines (a_value: INTEGER)
		do
			precondition_lines := a_value
		end

	set_postcondition_lines (a_value: INTEGER)
		do
			postcondition_lines := a_value
		end

	set_invariant_lines (a_value: INTEGER)
		do
			invariant_lines := a_value
		end

	add_precondition_lines (a_value: INTEGER)
		do
			precondition_lines := precondition_lines + a_value
		end

	add_postcondition_lines (a_value: INTEGER)
		do
			postcondition_lines := postcondition_lines + a_value
		end

	add_invariant_lines (a_value: INTEGER)
		do
			invariant_lines := invariant_lines + a_value
		end

	calculate_score
			-- Calculate DbC score
			-- Invariant bonus: +20% if present
		local
			l_base_score: INTEGER
		do
			if feature_count > 0 then
				l_base_score := ((require_count + ensure_count) * 50) // feature_count
			end
			if has_invariant then
				score := ((l_base_score * 120) // 100).min (100)
			else
				score := l_base_score.min (100)
			end
		end

end
