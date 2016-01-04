local socket = require "socket"
local room = require "room"
local loader = require "loader"

local function nexttick()
  return os.time() + math.random(10, 15)
end

local game = {
  server = nil,
  pulse = os.time(),
  tick = os.time(),
  nexttick = nexttick()
}

function game:start()
  game.server = assert(socket.bind("127.0.0.1", 55439))
  game.server:settimeout(0)
  local ip, port = game.server:getsockname()
  loader.load()
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

    for i, v in pairs(players) do
      prompt(v)
    end
  end
end

return game
