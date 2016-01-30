local f = require "functional"

local affect = {
  list = {
  }
}

function affect:getaffects(targetid)
  if not self.list[targetid] then
    self.list[targetid] = {} -- maybe move to init?
  end

  return self.list[targetid]
end

function affect:new(targetid, name, timeout, weardown)

  if timeout == nil then
    timeout = -1
  end

  local a = {
    name = name,
    timeout = timeout,
    weardown = weardown,
    id = uuid()
  }

  self:add(targetid, a)

  return a

end

function affect:add(targetid, aff)

  if not self.list[targetid] then
    self.list[targetid] = {}
  end

  table.insert(self.list[targetid], aff)

end

function affect:tick()

  self.list = f.map(self.list, function(l)
    return f.filter(l, function(a)

      if a.timeout >= 0 then
        a.timeout = a.timeout - 1

        return a.timeout >= 0
      end

      return true

    end)
  end)
end

return affect
