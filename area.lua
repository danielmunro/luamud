local lyaml = require "lyaml"
local room = require "room"

local area = {
  list = {}
}

function area:load()
  for i in io.popen("ls data/areas/"):lines() do
    print("loading " .. i .. " area file")
    local f = io.open("data/areas/" .. i, "r")
    local data = lyaml.load(f:read("*all")),
    f:close()

    self.list[data.id] = data

    for j, r in pairs(data.rooms) do
      if not r.id then
        print("Room without id")
        require "pl.pretty".dump(r)
        os.exit()
      end
      if room.list[r.id] then
        print("Room id collision: " .. r.id .. ", existing and new room below:")
        local prettydump = require "pl.pretty"
        prettydump(room.list[r.id])
        prettydump(r)
        os.exit()
      end
      room.list[r.id] = r
    end
  end
end

function area:save(a)
  local data = lyaml.dump({a})
  local f = io.open("data/areas/" .. a.id .. ".yaml", "w+")
  f:write(data)
  f:close()
end

function area:roomswap(roomid, areafromid, areatoid)
  self.list[areatoid].rooms[roomid] = self.list[areafromid].rooms[roomid]
  self.list[areafromid].rooms[roomid] = nil
  room.list[roomid].area = areatoid
end

function area:new(id)
  local newarea = {
    id = id,
    name = "",
    filename = "",
    credits = "",
    rooms = {}
  }

  self.list[id] = newarea
end

function area:addroom(room)
  self.list[room.area].rooms[room.id] = room
end

return area
