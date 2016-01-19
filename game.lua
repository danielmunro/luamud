local socket = require "socket"
local room = require "room"
local mob = require "mob"
local command = require "command"
local loader = require "loader"

local function nexttick()
  return os.time() + math.random(10, 15)
end

local function regen(mob, stat, regen)
  mob.attr[stat] = mob.attr[stat] or 0 + (mob.maxattr[stat] or 0 * regen)
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
  for i in io.popen("ls realm/"):lines() do
    if string.find(i,"%.are$") then loader:load("realm/" .. i) end
  end
  loader:done()
  print("Please telnet to localhost on port " .. port)
end

function game:checknewclient()
  local client = self.server:accept()

  if client then
    client:settimeout(0)

    local player = {
      client = client,
      roomid = room.rooms[3001].id,
      mob = mob:new("Foo", "human")
    }

    setmetatable(player, playermt)
    playermt.__index = playermt

    player.mob.isnpc = false
    room.rooms[player.roomid]:addmob(player.mob)
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

    local count = 0
    local failure = 0
    for i, m in pairs(mob.mobs) do
      count =  count + 1
      local r = room.rooms[m.roomid]
      if r == nil then
        failure = failure + 1
      else
        regen(m, "hp", r.healrate)
        regen(m, "mana", r.manarate)
        regen(m, "mv", r.healrate)
      end
    end
    print(count .. " mobs in boinga, "..failure.." failed room checks")
    for i, p in pairs(self.players) do
      prompt(p)
    end
  end
end

return game
