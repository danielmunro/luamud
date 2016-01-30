local f = require "functional"

local location = {
  mobs = {},
  rooms = {}
}

function location:addmob(mobid, roomid)
  self.mobs[mobid] = roomid
  table.insert(self.rooms[roomid], mobid)
end

function location:removemob(mobid, roomid)
  f.first(self.rooms[roomid], function(m)
    if m == mobid then
      table.remove(self.rooms[roomid], i)
      return true
    end
  end)
end

return location
