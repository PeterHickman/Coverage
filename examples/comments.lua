-- A comment

local s = [[
this
is
a
multiline
string]]

local answer = 42

---[[ This is really a single line comment
s = "so this is a real line of code"

--[[
print("You can't see me")
multiline
comment
]]

--[[ there is [a] 
something after
this ]] answer = 69

--[==[
this is a comment
--[=[
this is also a comment
--[[
the final comment
]]
except this
]=]
and this
]==]

local confused = [[
this is a multiline
string with a --
stuck in the middle of it]]

print("All done")