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

	total_with_require: INTEGER
			-- Features with preconditions

	total_with_ensure: INTEGER
			-- Features with postconditions

	total_classes: INTEGER
			-- Total classes analyzed

	total_with_invariant: INTEGER
			-- Classes with invariants

	total_score: INTEGER
			-- Overall DbC score (0-100)
		do
			if total_features > 0 then
				Result := ((total_with_require + total_with_ensure) * 50) // total_features
			end
			Result := Result.min (100)
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
		do
			-- Check for invariant in raw text
			l_has_invariant := a_content.has_substring ("%Ninvariant%N") or
				a_content.has_substring ("%Ninvariant%T") or
				a_content.has_substring ("%Ninvariant ")

			l_ast := parser.parse_string (a_content)
			if attached l_ast as la_ast and then not la_ast.has_errors then
				across la_ast.classes as cls loop
					create l_class_metrics.make (a_library_name, cls.name, a_file_path)
					l_class_metrics.set_has_invariant (l_has_invariant)

					total_classes := total_classes + 1
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
			end
		end

	reset
			-- Reset all metrics for fresh analysis
		do
			class_results.wipe_out
			total_features := 0
			total_with_require := 0
			total_with_ensure := 0
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

end
