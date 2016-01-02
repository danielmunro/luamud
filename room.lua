local mob = require "mob"
local persistence = require "persistence"

local room = {
  root = require "storage"
}


function room.new()
  local newroom = {
    id = "",
    name = "",
    description = "",
    directions = {},
    mobs = {}
  }

  return newroom
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

local function prune(room, pruned)
  if pruned[room.id] == nil then
    pruned[room.id] = true
    for i, v in pairs(room.mobs) do
      if not v.isnpc then
        table.remove(room.mobs, i)
      end
    end
    for i, v in pairs(room.directions) do
      prune(v, pruned)
    end
  end

  return room
end

if room.root then
  print("Pruning realm of linkdead users")

  prune(room.root, {})
else
  print("Creating new realm")

  local r1 = room.new()
  local r2 = room.new()

  local hassan = mob.new("Hassan")
  r1.id = "1"
  r1.name = "Room 1"
  r1.description = "An empty room with an open door to the north"
  r1.directions.north = r2
  table.insert(r1.mobs, hassan)

  r2.id = "2"
  r2.name = "Room 2"
  r2.description = "An empty room with an open door to the south"
  r2.directions.south = r1

  room.root = r1

  persistence.store("storage.lua", room.root)
end

return room
