--[[
 if you wish to add your own escape sequences,
 add them to this table, where the key is what the user will input,
 and the value is what will be included in the argument
--]]

local escape_sequences = {
    ['\\'] = "\\",
    ['"'] = '"',
}

local function format_error(message, index)
    return ("Syntax error: %s at character %s."):format(message, index)
end

--- Parse a string into a command with support for quotes to allow spaces in arguments, and escape sequences.
--- @param input string The string you wish to parse
--- @return table? parsed_command The output of the parser; is a dictionary with "name" for the first argument, and "arguments" for a table of the rest of the arguments. Will be nil if the command was parsed unsuccessfully.
--- @return string? error_message The error message that you can display to the user in the case that they incorrectly input a command. Will be nil if the command was parsed successfully.
local function command_parse(input)
    local input_length = #input

    local escaping = false
    local inside_quote = false

    local arguments = {}

    local current_argument = {
        _strings = {},

        add = function(self, stringToAdd)
            table.insert(self._strings, stringToAdd)
            return self
        end,

        clear_and_write = function(self)
            local strings = self._strings

            local argument_string = table.concat(strings)
            table.insert(arguments, argument_string)

            for k in pairs(strings) do
                strings[k] = nil
            end
        end,
    }


    for i = 1, input_length do
        local char = input:sub(i, i)

        local lastchar
        local lastchar_i = i - 1

        local nextchar
        local nextchar_i = i + 1


        if nextchar_i <= input_length then
            nextchar = input:sub(nextchar_i, nextchar_i)
        end

        if lastchar_i >= 1 then
            lastchar = input:sub(lastchar_i, lastchar_i)
        end

        if escaping then
            local sequence = escape_sequences[char]

            if not sequence then return nil, format_error("Invalid escape sequence '\\" .. char .. "'", i - 1) end

            current_argument:add(sequence)
            escaping = false
            goto next_character
        end

        if char == "\\" then
            escaping = true
            goto next_character
        end

        if char == " " then
            if not inside_quote then
                current_argument:clear_and_write()
                goto next_character
            end
        end

        if char == "\"" then
            inside_quote = not inside_quote

            if inside_quote then
                if lastchar and lastchar ~= " " then
                    return nil, format_error("Malformed quote, expected space before quote", i)
                end
            else
                if nextchar and nextchar ~= " " then
                    return nil, format_error("Malformed quote, expected space after quote", i)
                end
            end

            goto next_character
        end

        current_argument:add(char)
        ::next_character::
    end

    current_argument:clear_and_write()

    if inside_quote then return nil, format_error("Unclosed quote", input_length) end
    if escaping then return nil, format_error("Unfinished escape sequence", input_length) end

    local parsed_command = {
        name = arguments[1],
        arguments = {},
    }

    for i, argument in pairs(arguments) do
        if i ~= 1 then table.insert(parsed_command.arguments, argument) end
    end

    return parsed_command
end

return command_parse