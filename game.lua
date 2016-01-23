local socket = require "socket"
local room = require "room"
local mob = require "mob"
local command = require "command"
local location = require "location"
local area = require "area"
local player = require "player"

local DEFAULT_HEAL_RATE = 0.2
local DEFAULT_MANA_RATE = 0.3

local function nexttick()
  return os.time() + math.random(10, 15)
end

local function regen(mob, stat, regen)
  mob[stat] = mob[stat] + mob.attr[stat] * regen
  if mob[stat] > mob.attr[stat] then
    mob[stat] = mob.attr[stat]
  end
end

local game = {
  pulse = os.time(),
  tick = os.time(),
  nexttick = nexttick(),
  players = {},
  hour = 1
}

function game:start(port)
  game.server = assert(socket.bind("127.0.0.1", port))
  game.server:settimeout(0)
  area:load()
  print("Please telnet to localhost on port " .. port)
end

function game:checknewclient()
  local client = self.server:accept()

  if client then
    client:settimeout(0)
    local p = player:new(client)
    -- location:addmob(p.mob.id, room.START_ROOM)
    -- command.look(p)
    prompt(p)

    table.insert(self.players, p)
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

    -- regen
    for i, m in pairs(mob.list) do
      local r = room.list[location.mobs[m.id]]
      regen(m, "hp", r.healrate or DEFAULT_HEAL_RATE)
      regen(m, "mana", r.manarate or DEFAULT_MANA_RATE)
      regen(m, "mv", r.healrate or DEFAULT_HEAL_RATE)
    end

    -- save players, prompt them
    for i, p in pairs(self.players) do
      p:save()
      prompt(p)
    end

    -- save all areas -- boinga
    for i, a in pairs(area.list) do
      area:save(a)
    end

    print("tick --> " .. #room.list .. " rooms, " .. #mob.list .. " mobs, " .. #self.players .. " players")
    print("next tick in " .. (self.nexttick - os.time()) .. " seconds")
  end
end

return game
