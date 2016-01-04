local lyaml = require "lyaml"
local room = require "room"
local mob = require "mob"
local pretty = require "pl.pretty"

local f = io.open("realm/midgaard.yaml", "rb")
local content = f:read("*all")
f:close()
local data = lyaml.load(content)
local loader = {}
local rooms = {}

function loader.load()
  for i, r in pairs(data) do
    local nr = room:new()
    nr.name = r.name
    nr.description = r.description
    nr.id = i
    nr.directions = r.directions
    if r.mobs then
      for j, m in pairs(r.mobs) do
        if m.isnpc then
          nr:addmob(mob.new(j, m.race))
        end
      end
    end
    rooms[i] = nr
  end

  return rooms
end

function loader.addroom(room)
  rooms[room.id] = room
end

function loader.getrooms()
  return rooms
end

return loader
