note
	description: "Subclass of ET_EIFFEL_PARSER that exposes parsing results"
	author: "Generated"
	date: "$Date$"

class
	SIMPLE_GOBO_PARSER

inherit
	ET_EIFFEL_PARSER
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make (a_system_processor: like system_processor)
			-- Create parser
		do
			Precursor (a_system_processor)
		end

feature -- Access

	parsed_class: detachable ET_CLASS
			-- Last parsed class (exposed for simple API)
		do
			Result := last_class
		end

end
