local command_parse = require("command_parse")

local parsed_command = command_parse("a \"b c d\" e f g \"\\\"h\\\" i j k lmnop\"")
-- The above string without escapes for clarity: a "b c d" e f g "\"h\" i j k lmnop"

-- Expected result:
-- {
--    name = "a"
--    arguments = {
--        "a",
--        "b c d",
--        "e",
--        "f",
--        "g",
--        '"h" i j k lmnop',
--    }
-- }, nil

if parsed_command then
    print("Command name: ", parsed_command.name)
    for k,v in pairs(parsed_command.arguments) do
        print("Argument #"..k, v)
    end
end


local incorrectly_inputted_command, error_message = command_parse("a bcd\"")
-- Expected result:
-- nil,
-- "Syntax error: Malformed quote, expected space before quote at character 6."

if not incorrectly_inputted_command then
    print(error_message)
end