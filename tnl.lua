local race = require "race"
local mob = require "mob"

for i, r in pairs(race.races) do
  local m = mob:new("Foo", i, arg[1])
  local diff = m.xp.tnl - 900
  if diff > 0 then
    diff = "+" .. diff
  end
  print("Race: " .. r.name ..
  ", TNL: " .. m.xp.tnl .. " (" .. diff .. ")" ..
  ".\nStr: " .. m:getattr("str") ..
  " Int: " .. m:getattr("int") ..
  " Wis: " .. m:getattr("wis") ..
  " Dex: " .. m:getattr("dex") ..
  " Con: " .. m:getattr("con") ..
  " Cha: " .. m:getattr("cha") .. "\n")
end
