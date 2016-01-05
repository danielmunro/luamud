local lyaml = require "lyaml"
local persister = {}

function persister.persist(room)
  local data = lyaml.dump({room.rooms})
  local f = io.open("realm/midgaard.yaml", "w+")
  f:write(data)
  f:close()
end

return persister
