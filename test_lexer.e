note
    test: "test lexer"
class
    TEST_LEXER
feature
    test_string_with_class
        local
            s: STRING
        do
            s := "this has class in it"
            print (s)
        end
end
