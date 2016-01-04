local mob = require "mob"

local room = {
  rooms = nil
}

function room:new()
  local newroom = {
    id = "",
    name = "",
    description = "",
    directions = {},
    mobs = {}
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
