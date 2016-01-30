local location = require "location"
local command = require "command"
local room = require "room"
local race = require "race"
local lyaml = require "lyaml"

local login = {}
local loginmt = {}

-- prompt to select a mob as part of the login process.
function loginmt:selectmob()
  self.player:ask("By what name do you wish to be known (list for existing characters)? ", function(args)
    local mobname = args[1]
    if mobname == "list" then
      local list = "Your alts:\n"
      for i, m in pairs(self.player.mobs) do
        list = list .. m .. "\n"
      end
      self.player:send(list)
      self:selectmob()
    else
      for i, m in pairs(self.player.mobs) do
        if m == mobname then
          self.player:load(mobname)
          self.player:send("Welcome back.")
          location:addmob(self.player.mob.id, room.START_ROOM)
          command.look(self.player)
          return
        end
      end
      self.player:load(mobname)
      if self.player.mob then
        self.player:send("You do not possess that mob.")
        self.player.mob = nil
        return
      else
        local racecallback = function(args)
          if race.list[args[1]] then
            local race = args[1]
            self.player:send("Ok. Welcome to luamud.")
            self.player.mob = mob:new(mobname, race)
            self.player.mob.isnpc = false
            table.insert(self.player.mobs, self.player.mob.name)
            location:addmob(self.player.mob.id, room.START_ROOM)
            self.player:save()
            command.look(self.player)
          elseif args[1] == "help" then
          else
            self.player:ask("That's not a valid race. What race are you? ", racecallback)
          end
        end
        self.player:ask("New character. What race are you? ", racecallback)
      end
    end
  end)
end

-- New account - set a password
function loginmt:newaccountpassword()
  self.player:ask("Please enter a password: ", function(args)
    local p1 = table.concat(args, " ")
    if p1:len() < 5 then
      self.player:send("Passwords must be greater than 5 characters in length.")
      self:newaccountpassword()
    else
      self.player:ask("Confirm your password: ", function(args)
        local p2 = table.concat(args, " ")
        if p1 == p2 then
          self.player.password = p1
          self.player:send("Confirmed!")
          self.player:save()
          self:selectmob()
        else
          self.player:send("Passwords do not match. Try again.")
          self:newaccountpassword()
        end
      end)
    end
  end)
end

-- prompt the player for a login username and password if the account already
-- exists. Otherwise,
function loginmt:prompt()
  self.player:ask("What is your login username (not in-game character)? ", function(args)
    self.player.username = args[1]
    local f = io.open("data/players/" .. self.player.username .. ".yaml", "r")
    if f == nil then
      self.player:send("New account.")
      self:newaccountpassword()
    else
      local data = lyaml.load(f:read("*all"))
      f:close()
      self.player:ask("Password: ", function(args)
        local password = args[1]
        if data["password"] == password then
          self.player:send("Success!")
          self.player.password = password
          self.player.mobs = data["mobs"]
          self:selectmob()
        else
          self.player:send("Login failure.")
          self.player.client:close()
        end
      end)
    end
  end)
end

function login:new(player)
  local l = {
    player = player
  }

  setmetatable(l, loginmt)
  loginmt.__index = loginmt

  return l
end

return login
