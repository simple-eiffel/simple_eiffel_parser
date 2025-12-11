note
	description: "[
		DBC_ANALYZER - Analyzes Design by Contract coverage in Eiffel source files.

		Part of simple_eiffel_parser library. Provides semantic analysis of parsed
		Eiffel AST to extract DbC (require/ensure/invariant) metrics.

		Usage:
			analyzer: DBC_ANALYZER
			create analyzer.make
			analyzer.analyze_file_content (content, "my_class", "my_lib")
			print (analyzer.total_score.out + "%%")

		Score interpretation:
			0%:     No contracts (cold)
			1-24%:  Minimal contracts
			25-49%: Partial coverage
			50-74%: Good coverage
			75-89%: Strong coverage
			90-100%: Excellent coverage (hot)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DBC_ANALYZER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize analyzer
		do
			create parser.make
			create class_results.make (100)
		ensure
			parser_created: parser /= Void
		end

feature -- Access

	class_results: HASH_TABLE [DBC_CLASS_METRICS, STRING]
			-- Results by class name

	total_features: INTEGER
			-- Total features analyzed

	total_attributes: INTEGER
			-- Total attributes

	total_lines_of_code: INTEGER
			-- Total lines of code

	total_with_require: INTEGER
			-- Features with preconditions

	total_with_ensure: INTEGER
			-- Features with postconditions

	total_precondition_lines: INTEGER
			-- Individual precondition assertion lines

	total_postcondition_lines: INTEGER
			-- Individual postcondition assertion lines

	total_invariant_lines: INTEGER
			-- Individual class invariant assertion lines

	total_classes: INTEGER
			-- Total classes analyzed

	total_with_invariant: INTEGER
			-- Classes with invariants

	total_contract_lines: INTEGER
			-- Total contract assertion lines
		do
			Result := total_precondition_lines + total_postcondition_lines + total_invariant_lines
		end

	total_score: INTEGER
			-- Overall DbC score (0-100)
			-- Now based on contract lines per feature for more nuance
		do
			if total_features > 0 then
				-- Score based on contract density
				-- 2+ contracts per feature = 100%, scaled down from there
				Result := ((total_contract_lines * 50) // total_features).min (100)
			end
		end

feature -- Analysis

	analyze_file_content (a_content, a_class_name, a_library_name, a_file_path: STRING)
			-- Analyze a single file's content
		require
			content_not_empty: not a_content.is_empty
			class_name_not_empty: not a_class_name.is_empty
			library_name_not_empty: not a_library_name.is_empty
		local
			l_ast: detachable EIFFEL_AST
			l_class_metrics: DBC_CLASS_METRICS
			l_has_invariant: BOOLEAN
			l_contract_counts: TUPLE [pre, post, inv, loc, feat, attr: INTEGER]
		do
			-- Check for invariant in raw text
			l_has_invariant := a_content.has_substring ("%Ninvariant%N") or
				a_content.has_substring ("%Ninvariant%T") or
				a_content.has_substring ("%Ninvariant ")

			-- Count individual contract assertion lines
			l_contract_counts := count_contract_lines (a_content)

			l_ast := parser.parse_string (a_content)
			if attached l_ast as la_ast and then not la_ast.has_errors then
				across la_ast.classes as cls loop
					create l_class_metrics.make (a_library_name, cls.name, a_file_path)
					l_class_metrics.set_has_invariant (l_has_invariant)

					-- Set detailed metrics from contract line counting
					l_class_metrics.set_precondition_lines (l_contract_counts.pre)
					l_class_metrics.set_postcondition_lines (l_contract_counts.post)
					l_class_metrics.set_invariant_lines (l_contract_counts.inv)
					l_class_metrics.set_lines_of_code (l_contract_counts.loc)
					l_class_metrics.set_attribute_count (l_contract_counts.attr)

					-- Update totals
					total_classes := total_classes + 1
					total_precondition_lines := total_precondition_lines + l_contract_counts.pre
					total_postcondition_lines := total_postcondition_lines + l_contract_counts.post
					total_invariant_lines := total_invariant_lines + l_contract_counts.inv
					total_lines_of_code := total_lines_of_code + l_contract_counts.loc
					total_attributes := total_attributes + l_contract_counts.attr

					if l_has_invariant then
						total_with_invariant := total_with_invariant + 1
					end

					across cls.features as feat loop
						-- Skip attributes for DbC scoring
						if not feat.is_attribute then
							total_features := total_features + 1
							l_class_metrics.increment_feature_count

							if not feat.precondition.is_empty then
								total_with_require := total_with_require + 1
								l_class_metrics.increment_require_count
							end

							if not feat.postcondition.is_empty then
								total_with_ensure := total_with_ensure + 1
								l_class_metrics.increment_ensure_count
							end
						end
					end

					l_class_metrics.calculate_score
					class_results.force (l_class_metrics, cls.name)
				end
			else
				-- Parsing failed, still capture contract counts from text
				create l_class_metrics.make (a_library_name, a_class_name, a_file_path)
				l_class_metrics.set_has_invariant (l_has_invariant)
				l_class_metrics.set_precondition_lines (l_contract_counts.pre)
				l_class_metrics.set_postcondition_lines (l_contract_counts.post)
				l_class_metrics.set_invariant_lines (l_contract_counts.inv)
				l_class_metrics.set_lines_of_code (l_contract_counts.loc)
				l_class_metrics.set_attribute_count (l_contract_counts.attr)

				-- Use text-based feature count
				total_features := total_features + l_contract_counts.feat
				total_classes := total_classes + 1
				total_precondition_lines := total_precondition_lines + l_contract_counts.pre
				total_postcondition_lines := total_postcondition_lines + l_contract_counts.post
				total_invariant_lines := total_invariant_lines + l_contract_counts.inv
				total_lines_of_code := total_lines_of_code + l_contract_counts.loc
				total_attributes := total_attributes + l_contract_counts.attr

				l_class_metrics.calculate_score
				class_results.force (l_class_metrics, a_class_name)
			end
		end

	reset
			-- Reset all metrics for fresh analysis
		do
			class_results.wipe_out
			total_features := 0
			total_attributes := 0
			total_lines_of_code := 0
			total_with_require := 0
			total_with_ensure := 0
			total_precondition_lines := 0
			total_postcondition_lines := 0
			total_invariant_lines := 0
			total_classes := 0
			total_with_invariant := 0
		ensure
			cleared: total_features = 0 and total_classes = 0
		end

feature -- Color mapping

	color_for_score (a_score: INTEGER): STRING
			-- Get dark-mode color for score
		do
			if a_score = 0 then
				Result := "#1a1a1a"  -- Near-black (cold/dead)
			elseif a_score < 25 then
				Result := "#2d1f3d"  -- Dark purple
			elseif a_score < 50 then
				Result := "#4a2c4a"  -- Muted magenta
			elseif a_score < 75 then
				Result := "#8b4513"  -- Burnt orange
			elseif a_score < 90 then
				Result := "#cd5c00"  -- Orange
			else
				Result := "#ff4500"  -- Red-orange (hot)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	parser: EIFFEL_PARSER
			-- Eiffel source parser

	count_contract_lines (a_content: STRING): TUPLE [pre, post, inv, loc, feat, attr: INTEGER]
			-- Count individual contract assertion lines in content.
			-- Returns [precondition_lines, postcondition_lines, invariant_lines, loc, features, attributes]
			-- Uses simple state machine: track when inside require/ensure/invariant blocks
		local
			l_lines: LIST [STRING]
			l_line, l_trimmed: STRING
			l_in_note, l_in_feature_section: BOOLEAN
			l_in_precondition, l_in_postcondition, l_in_invariant: BOOLEAN
			l_pre, l_post, l_inv, l_loc, l_feat, l_attr: INTEGER
			l_first_char: CHARACTER
		do
			l_lines := a_content.split ('%N')

			across l_lines as ic loop
				l_line := ic
				l_trimmed := l_line.twin
				l_trimmed.left_adjust
				l_trimmed.right_adjust

				-- Track note section (skip it)
				if l_trimmed.starts_with ("note") then
					l_in_note := True
				end

				-- Class declaration ends note section
				if l_trimmed.starts_with ("class") or l_trimmed.starts_with ("deferred class") or
				   l_trimmed.starts_with ("expanded class") or l_trimmed.starts_with ("frozen class") then
					l_in_note := False
					l_in_feature_section := False
					l_in_precondition := False
					l_in_postcondition := False
				end

				-- Track feature sections
				if l_trimmed.starts_with ("feature") then
					l_in_feature_section := True
					l_in_precondition := False
					l_in_postcondition := False
				end

				-- Count features: single-tab indent, starts lowercase, has : or (
				if l_in_feature_section and l_line.count > 1 and then
				   l_line.item (1) = '%T' and then
				   (l_line.count < 2 or else l_line.item (2) /= '%T') then
					if l_trimmed.count > 0 then
						l_first_char := l_trimmed.item (1)
						if l_first_char >= 'a' and l_first_char <= 'z' then
							if l_trimmed.has (':') or l_trimmed.has ('(') then
								l_feat := l_feat + 1
								-- Attribute: has type (:) but no body keywords
								if l_trimmed.has (':') and not l_trimmed.has_substring (" do") and
								   not l_trimmed.has_substring (" once") and
								   not l_trimmed.has_substring (" external") and
								   not l_trimmed.has_substring (" deferred") then
									l_attr := l_attr + 1
								end
							end
						end
					end
				end

				-- Track contract blocks and count individual assertion lines
				if l_trimmed.starts_with ("require") then
					l_in_precondition := True
					l_in_postcondition := False
				elseif l_trimmed.starts_with ("ensure") then
					l_in_postcondition := True
					l_in_precondition := False
				elseif l_trimmed.same_string ("invariant") then
					l_in_invariant := True
					l_in_precondition := False
					l_in_postcondition := False
				elseif l_in_precondition and (
					l_trimmed.same_string ("local") or
					l_trimmed.same_string ("do") or
					l_trimmed.same_string ("once") or
					l_trimmed.same_string ("deferred") or
					l_trimmed.starts_with ("external") or
					l_trimmed.same_string ("attribute")) then
					l_in_precondition := False
				elseif l_in_postcondition and (
					l_trimmed.same_string ("end") or
					l_trimmed.same_string ("rescue")) then
					l_in_postcondition := False
				elseif l_in_invariant and l_trimmed.same_string ("end") then
					l_in_invariant := False
				elseif l_in_precondition and not l_trimmed.is_empty and not l_trimmed.starts_with ("--") then
					l_pre := l_pre + 1
				elseif l_in_postcondition and not l_trimmed.is_empty and not l_trimmed.starts_with ("--") then
					l_post := l_post + 1
				elseif l_in_invariant and not l_trimmed.is_empty and not l_trimmed.starts_with ("--") then
					l_inv := l_inv + 1
				end

				-- Count line if not: in note section, comment, or blank
				if not l_in_note and not l_trimmed.is_empty and not l_trimmed.starts_with ("--") then
					l_loc := l_loc + 1
				end
			end

			Result := [l_pre, l_post, l_inv, l_loc, l_feat, l_attr]
		end

end
