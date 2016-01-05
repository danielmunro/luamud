local socket = require "socket"
local room = require "room"

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
  nexttick = nexttick()
  hour = 1
}

function game:start()
  game.server = assert(socket.bind("127.0.0.1", 55439))
  game.server:settimeout(0)
  local ip, port = game.server:getsockname()
  room:load()
  print("Please telnet to localhost on port " .. port)
end

function game:newclient()
  local client = self.server:accept()

  if client then
    client:settimeout(0)

    return client
  end
end

function game:loop(players)
  local time = os.time()

  if time > self.pulse then
    self.pulse = time
  end

  if time > self.nexttick then
    self.tick = time
    self.nexttick = nexttick()

    for i, p in pairs(players) do
      local rate = p.room.regen or .1
      regen(p.mob, "hp", rate)
      regen(p.mob, "mana", rate)
      regen(p.mob, "mv", rate)
      prompt(p)
    end
  end
end

return game
