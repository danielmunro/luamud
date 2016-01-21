local mob = require "mob"

local room = {
  list = {},
  START_ROOM = "start"
}

function room:new()
  local newroom = {
    id = uuid(),
    name = "",
    description = "",
    area = "",
    directions = {},
    items = {}
  }

  self.list[newroom.id] = newroom

  return newroom
end

function room:to(startroomid, direction, endroomid)
  self.list[startroomid].directions[direction] = endroomid
end

function room:update(roomid, property, value)
  self.list[roomid][property] = value
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
