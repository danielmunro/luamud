local attributes = require "attributes"
local race = require "race"
local skill = require "skill"
local class = require "class"
local mob = {}

local function rawgain(primary, secondary)
  return (primary * 2/3) + (secondary * 1/4)
end

function mob:getattr(attrname)
  local rattr = race.races[self.race]["attr"][attrname] or 0;
  local attr = self.attr[attrname] or 0 + rattr
  local maxattr = rattr + 4

  if self.class then
    local amount = class.classes[self.class]["attr"][attrname] or 0
    if maxattr then
      maxattr = maxattr + amount
    end
    attr = attr + amount
  end

  if maxattr and attr > maxattr then
    return maxattr
  else
    return attr
  end
end

function mob:new(name, racetype, classtype)

  if racetype == nil then
    racetype = "critter"
  end

  local tolevel = race:tolevel(racetype)
  local m = {
    name = name,
    isnpc = true,
    race = racetype,
    level = 1,
    trains = 1,
    practices = 5,
    trainer = false,
    xp = {
      total = tolevel,
      tolevel = tolevel,
      tnl = tolevel
    },
    skills = {},
    spells = {},
    items = {},
    class = classtype,
    attr = {
      hp = 20,
      mana = 100,
      mv = 100,
      hit = 1,
      dam = 1
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

function mob:levelup()
  self.maxattr["hp"] = self.maxattr["hp"] + rawgain(self:getattr("con"), self:getattr("str"))
  self.maxattr["mana"] = self.maxattr["mana"] + rawgain(self:getattr("wis"), self:getattr("int"))
  self.maxattr["mv"] = self.maxattr["mv"] + rawgain(self:getattr("dex"), self:getattr("cha"))

  self.trains = self.trains + 1

  if self.isnpc then
    -- apply trains
  end
end

return mob
