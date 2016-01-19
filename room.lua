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
    exdescriptions = {},
    directions = {},
    mobs = {},
    items = {},
    healrate = 1,
    manarate = 1
  }

  setmetatable(newroom, self)
  self.__index = self

  return newroom
end

function room:addmob(mob)
  table.insert(self.mobs, mob)
  mob:setroomid(self.id)
end

function room:removemob(mob)
  for i, v in pairs(self.mobs) do
    if v == mob then
      table.remove(self.mobs, i)
      break
    end
  end
end

function room:load(loader)
  while true do
    local line = loader:nextbuf()
    local id = tonumber(string.sub(line, 2))

    if id == nil then
      print("error getting room id on line " .. loader.line .. ", cursor " .. loader.cursor .. ": " .. loader.buf[loader.line] .. " (" .. loader.filename .. ")")
      os.exit()
    end
    if id == 0 then
      return
    end
    local r = self:new()
    r.id = id
    r.name = loader:string()
    r.description = loader:string()
    loader:nextbuf() -- area id, room flags, sector type
    local directive = loader:character()
    while true do
      if directive == "S" then
        loader:nextbuf()
        break
      elseif directive == "D" then
        local door = tonumber(loader:character(true))
        local direction = 0
        if door == 0 then
          direction = "north"
        elseif door == 1 then
          direction = "east"
        elseif door == 2 then
          direction = "south"
        elseif door == 3 then
          direction = "west"
        elseif door == 4 then
          direction = "up"
        elseif door == 5 then
          direction = "down"
        else
          print("door bad num: " .. tostring(door))
          require "pl.pretty".dump(r)
          os.exit()
        end
        -- print("exit: "..loader:string()) -- Exit~
        -- print("keyword: "..loader:string()) -- keyword
        -- print("locks: "..loader:value(true)) -- locks
        -- print("key: "..loader:value(true)) -- key
        loader:string()
        loader:string()
        loader:value(true)
        loader:value(true)
        r.directions[direction] = tonumber(loader:value(true))
      elseif directive == "E" then
        -- extra data
        r.exdescriptions[loader:string()] = loader:string()
      elseif directive == "H" then
        loader:character()
        r.healrate = loader:value(true)
      elseif directive == "M" then
        loader:character()
        r.manarate = loader:value(true)
      elseif directive == "O" then
        r.owner = loader:string()
      elseif directive == "C" then
        r.clan = loader:value(true)
        loader:nextbuf()
      elseif directive == "B" then
        r.target = loader:value(true)
        loader:nextbuf()
      else
        print("bad directive: " .. directive .. " on line " .. loader.line .. ", cursor " .. loader.cursor .. ": " .. loader.buf[loader.line])
        require "pl.pretty".dump(r)
        os.exit()
      end
      directive = loader:character()
    end
    self.rooms[r.id] = r
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
