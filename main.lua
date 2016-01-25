local game = require "game"
local command = require "command"
local room = require "room"
local location = require "location"
local random = math.random

math.randomseed(os.time())

function map(array, func)
  local newarray = {}
  for i, v in pairs(array) do
    newarray[i] = func(v, i)
  end

  return newarray
end

function each(array, func)
  for i, v in pairs(array) do
    func(v, i)
  end
end

function first(array, func)
  if not func then
    func = function(v, i) return v end
  end

  for i, v in pairs(array) do
    local r = func(v, i)

    if r then return r end
  end
end

function uuid()
    local template ='xxxyxxxyxxxyxxxyxxxyxxxyxxxyxxxy'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function split(input)
  local result = {}

  for i in string.gmatch(input, "%S+") do table.insert(result, i) end

  return result
end

function match(key, input)
  return first(split(key), function(k)
    return string.find(k, input) == 1
  end)
end

local function findcommand(input)
  local match = {}

  if not input then return nil end

  each(command, function(c, i)
    if string.find(i, input) == 1 then match[i] = c end
  end)

  local p = first(command.priority, function(p, i)
    if string.find(i, input) == 1 then return match[p] end
  end)

  if p then return p end

  return first(match)
end

function broadcast(message)
  each(game.players, function(p) p:send(message) end)
end

function broadcastroom(playersender, message)

  local senderlocation = location.mobs[playersender.mob.id]

  each(game.players, function(p)
    if senderlocation == location.mobs[p.mob.id] and p ~= playersender then
      p:send(message)
    end
  end)

end

game:start(arg[1])

while 1 do

    game:loop()

    each(game.players, function(p, i)
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

        if not p.callback then p:prompt() end
        if input ~= "!" then p.lastinput = input end
      end

    end)
end
