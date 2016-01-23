local mob = require "mob"
local race = require "race"
local lyaml = require "lyaml"
local room = require "room"
local location = require "location"
local command = require "command"
local item = require "item"

local player = {}
local playermt = {}

function playermt:send(message)
  self.client:send(message .. "\n")
end

function playermt:ask(message, callback)
  self.client:send(message)
  self.callback = callback
end

function playermt:save()
  if self.mob then
    local f = io.open("data/mobs/" .. self.mob.name .. ".yaml", "w")
    f:write(lyaml.dump({{
      mob = self.mob,
      inv = item.inv[self.mob.id]
    }}))
    f:close()
  end
  local f = io.open("data/players/" .. self.username .. ".yaml", "w")
  local data = {
    username = self.username,
    password = self.password, -- very insecure
    mobs = self.mobs
  }
  f:write(lyaml.dump({data}))
  f:close()
end

function playermt:load(mobname)
  local f = io.open("data/mobs/" .. mobname .. ".yaml", "r")
  local data = lyaml.load(f:read("*all"))
  f:close()

  self.mob = data["mob"]
  item.inv[self.mob.id] = data["inv"]
end

function playermt:mobprompt()
  self:ask("By what name do you wish to be known (list for existing characters)? ", function(args)
    local mobname = args[1]
    if mobname == "list" then
      local list = "Your alts:\n"
      for i, m in pairs(self.mobs) do
        list = list .. m .. "\n"
      end
      self:send(list)
      self:mobprompt()
    else
      for i, m in pairs(self.mobs) do
        if m == mobname then
          self:load(mobname)
          self:send("Welcome back.")
          location:addmob(self.mob.id, room.START_ROOM)
          command.look(self)
          return
        end
      end
      self:load(mobname)
      if self.mob then
        self:send("You do not possess that mob.")
        self.mob = nil
        return
      else
        local racecallback = function(args)
          if race.list[args[1]] then
            local race = args[1]
            self:send("Ok. Welcome to luamud.")
            self.mob = mob:new(mobname, race)
            self.mob.isnpc = false
            table.insert(self.mobs, self.mob.name)
            location:addmob(self.mob.id, room.START_ROOM)
            self:save()
            command.look(self)
          elseif args[1] == "help" then
          else
            self:ask("That's not a valid race. What race are you? ", racecallback)
          end
        end
        self:ask("New character. What race are you? ", racecallback)
      end
    end
  end)
end

function playermt:passwordprompt()
  self:ask("Please enter a password: ", function(args)
    local p1 = table.concat(args, " ")
    if p1:len() < 5 then
      self:send("Passwords must be greater than 5 characters in length.")
      self:passwordprompt()
    else
      self:ask("Confirm your password: ", function(args)
        local p2 = table.concat(args, " ")
        if p1 == p2 then
          self.password = p1
          self:send("Confirmed!")
          self:save()
          self:mobprompt()
        else
          self:send("Passwords do not match. Try again.")
          self:passwordprompt()
        end
      end)
    end
  end)
end

function player:new(client)
  local p = {
    username = "",
    password = "",
    client = client,
    mobs = {}
    --client = client,
    --mob = mob:new("Foo", "human")
  }

  setmetatable(p, playermt)
  playermt.__index = playermt
  --p.mob.isnpc = false

  p:ask("What is your login username (not in-game character)? ", function(args)
    p.username = args[1]
    local f = io.open("data/players/" .. p.username .. ".yaml", "r")
    if f == nil then
      p:send("New account.")
      p:passwordprompt()
    else
      local data = lyaml.load(f:read("*all"))
      f:close()
      p:ask("Password: ", function(args)
        local password = args[1]
        if data["password"] == password then
          p:send("Success!")
          p.password = password
          p.mobs = data["mobs"]
          p:mobprompt()
        else
          p:send("Login failure.")
          p.client:close()
        end
      end)
    end
  end)

  return p
end

return player
