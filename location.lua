local f = require "functional"

local location = {
  mobs = {},
  rooms = {}
}

function location:addmob(mobid, roomid)
  self.mobs[mobid] = roomid
  if self.rooms[roomid] then
    table.insert(self.rooms[roomid], mobid)
  else
    self.rooms[roomid] = {}
    table.insert(self.rooms[roomid], mobid)
  end
end

function location:removemob(mobid, roomid)
  if self.rooms[roomid] then
    f.first(self.rooms[roomid], function(m)
      if m == mobid then
        table.remove(self.rooms[roomid], i)
        return true
      end
    end)
  end
end

return location
