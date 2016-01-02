local socket = require "socket"
local persistence = require "persistence"
local room = require "room"

function nexttick()
  return os.time() + math.random(10, 15)
end

local game = {
  server = assert(socket.bind("*", 0)),
  pulse = os.time(),
  tick = os.time(),
  nexttick = nexttick()
}
local ip, port = game.server:getsockname()
game.server:settimeout(0)

print("Please telnet to localhost on port " .. port)

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

    print("saving to storage")

    persistence.store("storage.lua", room.root)

    for i, v in pairs(players) do
      prompt(v)
    end
  end
end

return game
