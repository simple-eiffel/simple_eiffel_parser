note
	description: "Parse error information"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_PARSE_ERROR

create
	make

feature {NONE} -- Initialization

	make (a_message: STRING; a_line, a_column: INTEGER)
			-- Create parse error
		require
			message_not_empty: a_message /= Void and then not a_message.is_empty
			line_valid: a_line >= 1
			column_valid: a_column >= 1
		do
			message := a_message
			line := a_line
			column := a_column
			severity := Severity_error
		ensure
			message_set: message = a_message
			line_set: line = a_line
			column_set: column = a_column
		end

feature -- Access

	message: STRING
			-- Error message

	line: INTEGER
			-- Line number

	column: INTEGER
			-- Column number

	severity: INTEGER
			-- Error severity

feature -- Constants

	Severity_error: INTEGER = 1
	Severity_warning: INTEGER = 2
	Severity_info: INTEGER = 3
	Severity_hint: INTEGER = 4

feature -- Modification

	set_severity (a_severity: INTEGER)
			-- Set error severity
		do
			severity := a_severity
		ensure
			severity_set: severity = a_severity
		end

feature -- Query

	severity_string: STRING
			-- Severity as string
		do
			inspect severity
			when Severity_error then
				Result := "error"
			when Severity_warning then
				Result := "warning"
			when Severity_info then
				Result := "info"
			when Severity_hint then
				Result := "hint"
			else
				Result := "unknown"
			end
		end

invariant
	message_not_empty: message /= Void and then not message.is_empty
	line_valid: line >= 1
	column_valid: column >= 1

end
