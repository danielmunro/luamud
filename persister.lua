local lyaml = require "lyaml"
local loader = require "loader"
local persister = {}

function persister.persist(room)

  local data = lyaml.dump({loader.getrooms()})
  print(data)
  local f = io.open("realm/midgaard.yaml", "w+")
  f:write(data)
  f:close()
end

return persister
