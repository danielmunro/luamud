local game = require "game"
local command = require "command"
local room = require "room"

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
  for i, p in pairs(game.players) do
    p:send(message)
  end
end

function broadcastroom(playersender, message)
  for i, p in pairs(game.players) do
    if p.room.id == id and p ~= playersender then
      p:send(message)
    end
  end
end

function prompt(player)
  player.client:send("\n" .. player.mob:getattr("hp") .. "hp " .. player.mob:getattr("mana") .. "mana " .. player.mob:getattr("mv") .. "mv> ")
end

game:start()

while 1 do

    game:loop()

    for i, p in pairs(game.players) do
      local input, err = p.client:receive()

      if err == "closed" then table.remove(game.players, i)
      elseif input then
        local args = split(input)
        local playeraction = findcommand(args[1])

        if playeraction then
          playeraction(p, args)
        else
          p:send("What?")
        end

        prompt(p)
      end
    end
end
