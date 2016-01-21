local game = require "game"
local command = require "command"
local room = require "room"
local location = require "location"
local random = math.random

math.randomseed(os.time())

function uuid()
    local template ='xxxyxxxyxxxyxxxyxxxyxxxyxxxyxxxy'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

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

function prompt(player)
  player.client:send("\n" .. player.mob.hp .. "hp " .. player.mob.mana .. "mana " .. player.mob.mv .. "mv> ")
end

function broadcast(message)
  for i, p in pairs(game.players) do
    p:send(message)
  end
end

function broadcastroom(playersender, message)
  local senderlocation = location.mobs[playersender.mob.id]
  for i, p in pairs(game.players) do
    local plocation = location.mobs[p.mob.id]
    if senderlocation == plocation and p ~= playersender then
      p:send(message)
    end
  end
end

game:start(arg[1])

while 1 do

    game:loop()

    for i, p in pairs(game.players) do
      local input, err = p.client:receive()

      if err == "closed" then
        table.remove(game.players, i)
      elseif input then
        if input == "!" then input = p.lastinput end
        local args = split(input)

        if p.callback then
          local cb = p.callback
          p.callback = nil
          cb(args)
        else
          local playeraction = findcommand(args[1])

          if playeraction then
            playeraction(p, args)
          else
            p:send("What?")
          end
        end

        if not p.callback then prompt(p) end
        if input ~= "!" then p.lastinput = input end
      end
    end
end
