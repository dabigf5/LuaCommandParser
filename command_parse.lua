--[[
 if you wish to add your own escape sequences,
 add them to this table, where the key is what the user will input,
 and the value is what will be included in the argument
--]]

local escapeSequences = {
    ['\\'] = "\\",
    ['"'] = '"',
}

local function formatError(message, index)
    return ("Syntax error: %s at character %s."):format(message, index)
end

--- Parse a string into a command with support for quotes to allow spaces in arguments, and escape sequences.
--- @param input string The string you wish to parse
--- @return table? parsedCommand The output of the parser; is a dictionary with "name" for the first argument, and "arguments" for a table of the rest of the arguments. Will be nil if the command was parsed unsuccessfully.
--- @return string? errorMessage The error message that you can display to the user in the case that they incorrectly input a command. Will be nil if the command was parsed successfully.
local function commandParse(input)
    local inputLength = #input

    local escaping = false
    local insideQuote = false

    local arguments = {}

    local currentArgument = {
        _strings = {},

        add = function(self, stringToAdd)
            table.insert(self._strings, stringToAdd)
            return self
        end,

        clearAndWrite = function(self)
            local strings = self._strings

            local argumentString = table.concat(strings)
            table.insert(arguments, argumentString)

            for k in pairs(strings) do
                strings[k] = nil
            end
        end,
    }


    for i = 1, inputLength do
        local char = input:sub(i, i)

        local lastchar
        local lastcharIndex = i - 1

        local nextchar
        local nextcharIndex = i + 1


        if nextcharIndex <= inputLength then
            nextchar = input:sub(nextcharIndex, nextcharIndex)
        end

        if lastcharIndex >= 1 then
            lastchar = input:sub(lastcharIndex, lastcharIndex)
        end

        if escaping then
            local sequence = escapeSequences[char]

            if not sequence then return nil, formatError("Invalid escape sequence '\\" .. char .. "'", lastcharIndex) end

            currentArgument:add(sequence)
            escaping = false
            goto nextCharacter
        end

        if char == "\\" then
            escaping = true
            goto nextCharacter
        end

        if char == " " then
            if not insideQuote then
                currentArgument:clearAndWrite()
                goto nextCharacter
            end
        end

        if char == "\"" then
            insideQuote = not insideQuote

            if insideQuote then
                if lastchar and lastchar ~= " " then
                    return nil, formatError("Malformed quote, expected space before quote", i)
                end
            else
                if nextchar and nextchar ~= " " then
                    return nil, formatError("Malformed quote, expected space after quote", i)
                end
            end

            goto nextCharacter
        end

        currentArgument:add(char)
        ::nextCharacter::
    end

    currentArgument:clearAndWrite()

    if insideQuote then return nil, formatError("Unclosed quote", inputLength) end
    if escaping then return nil, formatError("Unfinished escape sequence", inputLength) end

    local parsedCommand = {
        name = arguments[1],
        arguments = {},
    }

    for i, argument in pairs(arguments) do
        if i ~= 1 then table.insert(parsedCommand.arguments, argument) end
    end

    return parsedCommand
end

return commandParse
