local mob = require "mob"
local lyaml = require "lyaml"
local item = require "item"
local login = require "login"

local player = {}
local playermt = {}

-- send a message to the player
function playermt:send(message)
  self.client:send(message .. "\n")
end

-- send a message to the player, and capture their next input for the provided
-- callback function.
function playermt:ask(message, callback)
  self.client:send(message)
  self.callback = callback
end

-- saves the player and the mob the player is logged in as.
function playermt:save()
  if self.mob then
    local f = io.open("data/mobs/" .. self.mob.name .. ".yaml", "w")
    f:write(lyaml.dump({{
      mob = self.mob,
      inv = item.inv[self.mob.id]
    }}))
    f:close()
  end
  local f = io.open("data/players/" .. self.username .. ".yaml", "w")
  local data = {
    username = self.username,
    password = self.password, -- very insecure
    mobs = self.mobs
  }
  f:write(lyaml.dump({data}))
  f:close()
end

-- load a mob.
function playermt:load(mobname)
  local f = io.open("data/mobs/" .. mobname .. ".yaml", "r")
  local data = lyaml.load(f:read("*all"))
  f:close()

  self.mob = data["mob"]
  mob.list[self.mob.id] = self.mob
  item.inv[self.mob.id] = data["inv"]
end

-- prompt the player.
function playermt:prompt()
  self.client:send("\n" .. self.mob.hp .. "hp " .. self.mob.mana .. "mana " .. self.mob.mv .. "mv> ")
end

-- create a new player table.
function player:new(client)
  local p = {
    username = "",
    password = "",
    client = client,
    mobs = {}
  }

  setmetatable(p, playermt)
  playermt.__index = playermt

  login:new(p):prompt()

  return p
end

return player
