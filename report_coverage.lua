------------------------------------------------------------------------------
-- Title:               report_coverage.lua
-- Description:         Report line coverage for lua source
-- Author:              Peter Hickman (peterhi@ntlworld.com)
-- Creation Date:       2008/01/06
-- Legal:               Copyright (C) 2008 Peter Hickman
--                      Under the terms of the MIT License
--                      http://www.opensource.org/licenses/mit-license.html
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- $ lua coverage.lua plxml.lua tests/*
-- Where 'plxml.lua' is the name of the code we want the coverage for
-- and 'tests/*' is the list of tests that will be run to generate the
-- coverage into a file called 'coverage.out'
--
-- or you can run it as
-- $lua coverage.lua testme.lua
--
-- To create the report you need to run
-- $ lua report_coverage.lua plxml.lua coverage.out > report.txt
-- Where 'plxml.lua' is the name of the source that the coverage was collected 
-- for and 'coverage.out' is the file of coverage stats collected above. The
-- 'coverage.out' parameter is optional and will default to that value if
-- omitted.
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- This section is just to see if a line from the source is blank, a comment or
-- actual code

local multiline = ''

-- Put into a function this make the code readable

local function deleteAfter( pos, data )
    if(pos == 1) then
        return ''
    else
        return data:sub(1,pos-1)
    end
end

-- See if the quotes in a line of code balancce their quotes (' or ") so the
-- we can tell if the -- or [[ are actually part of a string

local function balancedQuotes( pos, data )
    local is = ''

    if(pos == nil) then
        return false
    end

    for p=1,pos do
        if(is == '') then
            if(data:sub(p,p) == '"' or data:sub(p,p) == "'") then
                is = data:sub(p,p)
            end
        elseif(is == '"' and data:sub(p,p) == '"') then
            is = ''
        elseif(is == "'" and data:sub(p,p) == "'") then
            is = ''
        end
    end

    return is == ''
end

-- Given an opening [[ (possibly with several '='s in between) return the
-- closing string we should be looking for

local function getClosing( data )
    local text = ''
    local opening = false
    local closing = false

    for p=1,data:len() do
        if(data:sub(p,p) == '[') then
            if(opening == false) then
                opening = true
                text = text .. ']'
            elseif(closing == false) then
                closing = true
                text = text .. ']'
            end
        elseif(opening == true and closing == false) then
            text = text .. data:sub(p,p)
        end
    end

    return text
end

local function blank( data )
    local data = data

    if(multiline ~= '') then
        local pos = data:find(multiline,1,true)
        if(pos) then
            -- Found the closing string
            if(pos == 1) then
                data = ''
            else
                local endof = pos + string.len(multiline)
                data = data:sub(endof,-1)
            end
            multiline = ''
        else
            -- Still in a multiline comment
            return true
        end
    end

    local start_of_comment = data:find("--",1,true)
    if(not(balancedQuotes(start_of_comment, data))) then
        start_of_comment = nil
    end

    local start_of_string  = data:find("%[=*%[")
    if(not(balancedQuotes(start_of_string, data))) then
        start_of_string = nil
    end

    if(start_of_comment) then
        -- We have a comment
        if(start_of_string) then
            -- And a string (maybe)
            if(start_of_comment + 2 == start_of_string) then
                -- multiline comment
                multiline = getClosing(data:sub(start_of_string,-1))
                data = deleteAfter( start_of_comment, data )
            else
                -- What comes first?
                if(start_of_comment < start_of_string) then
                    -- Deal with the comment
                    data = deleteAfter( start_of_comment, data )
                else
                    -- Deal with the string
                    data = data:sub(start_of_string,-1)
                    multiline = ']]'
                end
            end
        else
            -- Just a comment
            data = deleteAfter( start_of_comment, data )
        end
    elseif(start_of_string) then
        -- We have a string but no comment
        data = data:sub(start_of_string,-1)
        multiline = ']]'
    end

    data = data:gsub("%s+","")

    if(data == '') then
        return true
    else
        return false
    end
end

-- Read the source in

local function readsource( filename )
    local lines = {}

    local inp = assert(io.open(filename,'r'))

    while true do
        local line = inp:read('*line')
        if not line then break end

        local data = {}
        data.source = line
        data.ignore = blank(line)
        data.count = 0

        lines[#lines+1] = data
    end

    inp:close()

    return lines
end

-- Add the coverage information

local function readcoverage( filename, lines )
    local inp = assert(io.open(filename,'r'))

    while true do
        local line, count = inp:read('*number', '*number')
        if not line then break end

        lines[line].count = lines[line].count + count
    end

    inp:close()
    
    return lines
end

-- Some lines don't seem to be counted

local function patchup( lines )
    for k,v in ipairs(lines) do
        if(v.ignore == false and v.count == 0) then
            -- end
            if(string.match(v.source, "^%s+end%s*$") ~= nil) then
                v.count = -1
            -- else
            elseif(string.match(v.source, "^%s+else%s*$") ~= nil) then
                v.count = -1
            -- local function
            elseif(string.match(v.source, "%s*local%s+function%s+") ~= nil) then
                v.count = -1
            -- return function
            elseif(string.match(v.source, "%s*return%s+function%s*%(") ~= nil) then
                v.count = -1
            end
        elseif(v.ignore == true and v.count ~= 0) then
            -- Flagged end of a long string look backwards
            -- to find the start of the string
            local count = v.count
            for p = k,1,-1 do
                if(lines[p].ignore == true) then
                    lines[p].count = -1
                else
                    lines[p].count = count
                    break
                end
            end
        end
    end

    return lines
end

local sourcefilename = arg[1]
local coverfilename  = arg[2] or 'coverage.out'

local lines = readsource(sourcefilename)
lines = readcoverage(coverfilename, lines)
lines = patchup(lines)

local total_source_lines = #lines
local total_code_lines = 0
local total_code_covered = 0

for k,v in ipairs(lines) do
    local ok = true

    if(v.ignore == false) then
        total_code_lines = total_code_lines + 1

        if(v.count == 0) then
            ok = false
        else
            total_code_covered = total_code_covered + 1
        end
    else
        ok = ''
    end

    print(k,ok,v.source)
end

print()
print("Total lines in file ..: " .. total_source_lines)
print("Total lines of code ..: " .. total_code_lines)
print("Code covered .........: " .. total_code_covered .. " (" .. string.format("%.2f",(total_code_covered / total_code_lines * 100)) .. "%)")
print("Code missed ..........: " .. (total_code_lines - total_code_covered))
