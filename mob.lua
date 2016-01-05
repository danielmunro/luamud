local attributes = require "attributes"
local race = require "race"
local mob = {}

function mob:getattr(attrname)
  local attr = self.attr[attrname] or 0 + race[self.race].attr[attrname] or 0

  if self.maxattr[attrname] and attr > self.maxattr[attrname] then
    return self.maxattr[attrname]
  else
    return attr
  end
end

function mob:new(name, racetype)

  if racetype == nil then
    racetype = "critter"
  end

  local m = {
    name = name,
    isnpc = true,
    race = racetype,
    level = 1,
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

  setmetatable(m, self)
  self.__index = self

  return m
end

return mob
