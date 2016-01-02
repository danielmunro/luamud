local game = require "game"
local room = require "room"
local command = {
  priority = {
    s = "south"
  }
}

function command.quit(player)
  for i, v in pairs(player.room.mobs) do
    if v == player.mob then
      table.remove(player.room.mobs, i)
      break
    end
  end
  player.client:close()
end

function command.gossip(player, args)
    table.remove(args, 1)
    broadcast(player.client:getpeername() .. " gossips, \"" .. table.concat(args, " ") .. "\"\n")
end

function command.look(player)
  local r = player.room

  local directions = {}
  for i, v in pairs(player.room.directions) do
    table.insert(directions, string.sub(i, 1, 1))
  end

  local mobs = {}
  for i, v in pairs(player.room.mobs) do
    if v ~= player.mob then
      table.insert(mobs, v.name .. " is here.\n");
    end
  end

  player.client:send(
    r.name .. "\n" ..
    r.description .. "\n\n" ..
    "Exits [" .. table.concat(directions) .. "]\n" ..
    table.concat(mobs)
  )
end

function command.create(player, args)
  if args[2] == "room" then
    direction = args[3]
    if room.isdirection(direction) then
      if player.room.directions[direction] then
        player.client:send("A room already exists.\n")
      else
        r = room.new();
        r.name = "A new room"
        r.description = "A new room has popped into existence from the void. It is up to you to customize it."
        player.room.directions[direction] = r
        r.directions[room.oppositedir(direction)] = player.room
        player.client:send("A room is summoned from the void.\n")
      end
    else
      player.client:send("That is not a direction.\n")
    end
  else
    player.client:send("Cannot create that.\n")
  end
end

local function move(player, direction)
  if player.room.directions[direction] then
    for i, v in pairs(player.room.mobs) do
      if v == player.mob then
        table.remove(player.room.mobs, i)
        break
      end
    end
    broadcastroom(player.room.id, player, player.mob.name .. " leaves heading " .. direction .. ".\n")
    player.room = player.room.directions[direction]
    broadcastroom(player.room.id, player, player.mob.name .. " arrives from the " .. room.oppositedir(direction) .. "\n")
    table.insert(player.room.mobs, player.mob)
    command.look(player)
  else
    player.client:send("Alas, that direction does not exist\n")
  end
end

function command.north(player)
  move(player, "north")
end

function command.south(player)
  move(player, "south")
end

function command.east(player)
  move(player, "east")
end

function command.west(player)
  move(player, "west")
end

function command.up(player)
  move(player, "up")
end

function command.down(player)
  move(player, "down")
end

function command.say(player, args)
  table.remove(args, 1)
  message = table.concat(args, " ")
  player.client:send("You say, \"" .. message .. "\"")
  broadcastroom(
    player.room.id,
    player,
    player.client:getpeername() .. " says, \"" .. message .. "\"\n"
  )
end

return command
