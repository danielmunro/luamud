local game = require "game"
local command = require "command"
local room = require "room"
local mob = require "mob"
local loader = require "loader"
local players = {}

local function split(input)
  local result = {}

  for i in string.gmatch(input, "%S+") do
    table.insert(result, i)
  end

  return result
end

local function findcommand(input)
  local match = {}

  if not input then return nil end

  for i, v in pairs(command) do
    if string.find(i, input) == 1 then
      match[i] = v
    end
  end

  for i, v in pairs(command.priority) do
    if string.find(i, input) == 1 then
      return match[v]
    end
  end

  for i, v in pairs(match) do
    return v
  end
end

function broadcast(message)
  for i, p in ipairs(players) do
    p.client:send(message)
  end
end

function broadcastroom(id, sender, message)
  for i, p in ipairs(players) do
    if p.room.id == id and p ~= sender then
      p.client:send(message)
    end
  end
end

function prompt(player)
  player.client:send("\n--> ")
end

game:start()

while 1 do

    game:loop(players)

    local newclient = game:newclient()
    local rooms = loader.getrooms()

    if newclient then
      local player = {
        client = newclient,
        room = rooms["town_center"],
        mob = mob.new("Foo", "human")
      }
      player.mob.isnpc = false
      player.room:addmob(player.mob)
      table.insert(players, player)
      command.look(player)
      prompt(player)
    end

    for i, p in ipairs(players) do
      local input, err = p.client:receive()

      if err == "closed" then table.remove(players, i)
      elseif input then
        local args = split(input)
        local playeraction = findcommand(args[1])

        if playeraction then
          playeraction(p, args)
        else
          p.client:send("What?\n")
        end

        prompt(p)
      end
    end
end
