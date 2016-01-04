local attributes = require "attributes"
local race = require "race"
local mob = {}

function mob.attr(m, attrname)
end

function mob.new(name, racetype)
  local m = {
    name = name,
    isnpc = true,
    race = race.new(racetype),
    attr = {
      hp = 20,
      mana = 100,
      mv = 100
    },
    maxattr = {
      hp = 20,
      mana = 100,
      mv = 100
    }
  }

  return m
end

return mob
