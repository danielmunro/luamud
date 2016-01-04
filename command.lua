local game = require "game"
local room = require "room"
local persister = require "persister"
local loader = require "loader"

local command = {
  priority = {
    s = "south"
  }
}

function command.help(player, args)
  local topic = args[2]
  if topic == "create" then
    player.client:send("'Create' is used to bring new objects into the game world.\n\nFor rooms, the syntax is: 'create room <direction> <room_id>'\n")
  else
    player.client:send("Use the help command to learn more about the game.\n")
  end
end

function command.saverealm(player)
  persister.persist(player.room)
  player.client:send("Realm persisted.\n");
end

function command.quit(player)
  player.room:removemob(player.mob)
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
        local rooms = loader.getrooms()
        if rooms[args[4]] then
          player.client:send("A room with that id exists.\n")
        else
          r = room:new();
          r.name = "A new room"
          r.description = "A new room has popped into existence from the void. It is up to you to customize it."
          player.room.directions[direction] = r.id
          r.directions[room.oppositedir(direction)] = player.room.id
          player.client:send("A room is summoned from the void.\n")
          loader.addroom(r)
        end
      end
    else
      player.client:send("That is not a direction.\n")
    end
  else
    player.client:send("Cannot create that.\n")
  end
end

function command.room(player, args)
  local prop = args[2]
  table.remove(args, 1)
  table.remove(args, 1)
  local value = table.concat(args, " ")
  if prop == "name" or prop == "description" then
    player.room[prop] = value
    player.client:send("Room " .. prop .. " updated.\n")
  elseif prop == "list" then
    local message = ""
    for i, v in pairs(loader.getrooms()) do
      message = message .. i .. ": " .. v.name .. "\n"
    end
    player.client:send("In-game rooms: " .. message);
  else
    player.client:send("Not understood.\n")
  end


end

local function move(player, direction)
  local rooms = loader.getrooms()
  local roomto = rooms[player.room.directions[direction]]
  local roomfrom = player.room

  if roomto then
    roomfrom:removemob(player.mob)
    broadcastroom(roomfrom.id, player, player.mob.name .. " leaves heading " .. direction .. ".\n")
    player.room = roomto
    broadcastroom(roomto.id, player, player.mob.name .. " arrives from the " .. room.oppositedir(direction) .. ".\n")
    roomto:addmob(player.mob)
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
