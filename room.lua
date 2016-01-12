local mob = require "mob"
local lyaml = require "lyaml"

local room = {
  rooms = {}
}

function room:new()
  local newroom = {
    id = #self.rooms+1,
    name = "",
    description = "",
    directions = {},
    mobs = {},
    items = {}
  }

  setmetatable(newroom, self)
  self.__index = self

  return newroom
end

function room:addmob(mob)
  table.insert(self.mobs, mob)
end

function room:removemob(mob)
  for i, v in pairs(self.mobs) do
    if v == mob then
      table.remove(self.mobs, i)
      break
    end
  end
end

function room:load()
  local f = io.open("realm/midgaard.yaml", "rb")
  local content = f:read("*all")
  f:close()
  self.rooms = lyaml.load(content)

  for i, r in pairs(self.rooms) do
    setmetatable(r, self)
    self.__index = self

    for j, m in pairs(r.mobs) do
      if m.isnpc then
        setmetatable(m, mob)
        mob.__index = mob
      else
        table.remove(r.mobs, j)
      end
    end
  end
end

function room.oppositedir(d)
  if d == "north" then return "south"
  elseif d == "south" then return "north"
  elseif d == "east" then return "west"
  elseif d == "west" then return "east"
  elseif d == "up" then return "down"
  elseif d == "down" then return "up"
  end
end

function room.isdirection(value)
  if value == "north" or value == "south" or value == "east" or value == "west" or value == "up" or value == "down" then
    return true
  else
    return false
  end
end

return room
