------------------------------------------------------------------------------
-- Title:               coverage.lua
-- Description:         Collect line coverage for lua source
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

-- The name of the source file to match
local match = nil

-- A table to hold the lines being encountered
local lines = {}

-- The highest line number encountered
local max = 0

local function hook()
    local info = debug.getinfo(2,"Sl")

    local source = info.source
    if(string.match(source,match)) then
        local line = info.currentline
        if(lines[line] == nil) then
            lines[line] = 1
            if(line > max) then
                max = line
            end
        else
            lines[line] = lines[line] + 1
        end
    end
end

-- The first argument is the source to check
match = arg[1]

-- If there is only one argument...
if(#arg == 1) then
    arg[2] = match
end

-- The rest of the arguments are programs to run
for p = 2,#arg do
    local filename = arg[p]

    local f = assert(loadfile(filename))

    debug.sethook(hook, "l")
    f()
    debug.sethook()
end

local out = assert(io.open('coverage.out','w'))
for p = 1,max do
    if(lines[p] ~= nil) then
        out:write(p .. ' ' .. lines[p] .. "\n")
    end
end
out:close()
