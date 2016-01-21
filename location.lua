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
    for i, m in pairs(self.rooms[roomid]) do
      if m == mobid then
        table.remove(self.rooms[roomid], i)
        return
      end
    end
  end
end

return location
