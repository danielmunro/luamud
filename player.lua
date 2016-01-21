local mob = require "mob"
local player = {}

local playermt = {}

function playermt:send(message)
  self.client:send(message .. "\n")
end

function playermt:ask(message, callback)
  self:send(message)
  self.callback = callback
end

function player:new(client)
  local p = {
    client = client,
    mob = mob:new("Foo", "human")
  }

  setmetatable(p, playermt)
  playermt.__index = playermt
  p.mob.isnpc = false

  return p
end

return player
