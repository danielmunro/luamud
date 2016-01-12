local socket = require "socket"
local room = require "room"
local mob = require "mob"
local command = require "command"

local function nexttick()
  return os.time() + math.random(10, 15)
end

local function regen(mob, stat, regen)
  mob.attr[stat] = mob.attr[stat] + (mob.maxattr[stat] * regen)
  if mob.attr[stat] > mob.maxattr[stat] then
    mob.attr[stat] = mob.maxattr[stat]
  end
end

local game = {
  pulse = os.time(),
  tick = os.time(),
  nexttick = nexttick(),
  players = {},
  hour = 1
}

local playermt = {}

function playermt:send(message)
  self.client:send(message .. "\n")
end

function game:start()
  game.server = assert(socket.bind("127.0.0.1", 55439))
  game.server:settimeout(0)
  local ip, port = game.server:getsockname()
  room:load()
  print("Please telnet to localhost on port " .. port)
end

function game:checknewclient()
  local client = self.server:accept()

  if client then
    client:settimeout(0)

    local player = {
      client = client,
      room = room.rooms[1],
      mob = mob:new("Foo", "giant")
    }

    setmetatable(player, playermt)
    playermt.__index = playermt

    player.mob.isnpc = false
    player.room:addmob(player.mob)
    command.look(player)
    prompt(player)
    table.insert(self.players, player)
  end
end

function game:loop()

  self:checknewclient()

  local time = os.time()

  if time > self.pulse then
    self.pulse = time
  end

  if time > self.nexttick then
    self.tick = time
    self.nexttick = nexttick()

    for i, p in pairs(self.players) do
      local rate = p.room.regen or .1
      regen(p.mob, "hp", rate)
      regen(p.mob, "mana", rate)
      regen(p.mob, "mv", rate)
      prompt(p)
    end
  end
end

return game
