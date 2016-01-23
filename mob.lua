local attributes = require "attributes"
local race = require "race"
local skill = require "skill"
local class = require "class"
local mob = {
  list = {}
}

local position = {
  DEAD = 0,
  MORTAL = 1,
  INCAP = 2,
  STUNNED = 3,
  SLEEPING = 4,
  RESTING = 5,
  SITTING = 6,
  FIGHTING = 7,
  STANDING = 8
}

local act = {
  IS_NPC = "A",
  SENTINEL = "B",
  SCAVENGER = "C",
  AGGRESSIVE = "F",
  STAY_AREA = "G",
  WIMPY = "H",
  PET = "I",
  TRAIN = "J",
  PRACTICE = "K",
  UNDEAD = "O",
  IS_WEAPONSMITH = "P",
  CLERIC = "Q",
  MAGE = "R",
  THIEF = "S",
  WARRIOR = "T",
  NOALIGN = "U",
  NOPURGE = "V",
  OUTDOORS = "W",
  IS_ARMOURER = "X",
  INDOORS = "Y",
  MOUNT = "Z",
  IS_HEALER = "aa",
  GAIN = "bb",
  UPDATE_ALWAYS = "cc",
  IS_CHANGER = "dd",
  NOTRANS = "ee"
}

local function rawgain(primary, secondary)
  return (primary * 2/3) + (secondary * 1/4)
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function mob:getattr(attrname)
  local rattr = race.list[self.race]["attr"][attrname] or 0;
  local attr = self.attr[attrname] or 0 + rattr
  local maxattr = rattr + 4

  if self.class then
    local amount = class.list[self.class]["attr"][attrname] or 0
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

function mob:baseattr(attrname)
  local rattr = race.list[self.race]["attr"][attrname] or 0;
  local attr = self.attr[attrname] or 0 + rattr

  return attr
end

function mob:new(name, racetype, classtype)

  if racetype == nil then
    racetype = "critter"
  end

  local tolevel = race:tolevel(racetype)
  local m = {
    id = uuid(),
    name = name,
    shortdesc = "",
    desc = "",
    isnpc = true,
    race = racetype,
    level = 1,
    trains = 1,
    practices = 5,
    position = position.STANDING,
    act = {},
    xp = {
      total = tolevel,
      tolevel = tolevel,
      tnl = tolevel
    },
    attr = {
      hp = 20,
      mana = 100,
      mv = 100
    },
    hp = 20,
    mana = 100,
    mv = 100
  }

  self.list[m.id] = m

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
