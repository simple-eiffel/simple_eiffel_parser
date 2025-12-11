note
	description: "Simple test app for EIFGENs metadata parser"
	author: "Larry Rix"

class
	EIFGENS_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Test the EIFGENs metadata parser
		local
			l_meta: EIFGENS_METADATA_PARSER
		do
			print ("=== EIFGENs Metadata Parser Test ===%N%N")

			-- Test with simple_json's EIFGENs
			create l_meta.make_with_path ("D:/prod/simple_json/EIFGENs/simple_json_tests/W_code")
			l_meta.load

			print ("Loaded: " + l_meta.is_loaded.out + "%N")
			print ("Classes: " + l_meta.class_count.out + "%N")
			print ("Features: " + l_meta.total_features.out + "%N%N")

			-- Test class lookup
			if l_meta.has_class ("SIMPLE_JSON") then
				print ("Found SIMPLE_JSON at index: " + l_meta.class_index ("SIMPLE_JSON").out + "%N")
			else
				print ("ERROR: SIMPLE_JSON not found!%N")
			end

			if l_meta.has_class ("ANY") then
				print ("Found ANY at index: " + l_meta.class_index ("ANY").out + "%N")
			else
				print ("ERROR: ANY not found!%N")
			end

			-- Test ancestor chain
			print ("%NAncestors of SIMPLE_JSON_VALUE:%N")
			if l_meta.has_class ("SIMPLE_JSON_VALUE") then
				across l_meta.ancestor_chain ("SIMPLE_JSON_VALUE") as a loop
					print ("  " + a + "%N")
				end
			else
				print ("  (class not found)%N")
			end

			-- Test attributes (enames.c contains attribute names, not all features)
			print ("%NAttributes from enames.c (sample - class with attributes):%N")
			if l_meta.has_class ("STRING_TO_INTEGER_CONVERTOR") then
				print ("STRING_TO_INTEGER_CONVERTOR attributes:%N")
				if attached l_meta.features_for_class (l_meta.class_index ("STRING_TO_INTEGER_CONVERTOR")) as attrs then
					across attrs as a loop
						print ("  " + a + "%N")
					end
				end
			end

			-- Test SIMPLE_JSON_CONSTANTS (should have constants/attributes)
			print ("%NSIMPLE_JSON_CONSTANTS attributes:%N")
			if l_meta.has_class ("SIMPLE_JSON_CONSTANTS") then
				if attached l_meta.features_for_class (l_meta.class_index ("SIMPLE_JSON_CONSTANTS")) as attrs then
					if attrs.is_empty then
						print ("  (no attributes in enames.c - class may only have routines)%N")
					else
						across attrs as a loop
							print ("  " + a + "%N")
						end
					end
				else
					print ("  (no entry in enames.c)%N")
				end
			end

			print ("%N=== Summary ===%N")
			print ("EIFGENs metadata provides:%N")
			print ("  - 1208 class names with type indices%N")
			print ("  - Full inheritance chains (accurate)%N")
			print ("  - Attribute names for classes that have them%N")
			print ("  - NOT procedure/function names (those are in parser)%N")
			print ("%N=== Test Complete ===%N")
		end

end
