return function(busted)
  local function execAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)

    if propagate and parent then execAll(descriptor, parent, propagate) end

    local list = current[descriptor]

    if list then
      for _, v in pairs(list) do
        busted.safe(descriptor, v.run, v)
      end
    end
  end

  local function dexecAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)
    local list = current[descriptor]

    if list then
      for _, v in pairs(list) do
        busted.safe(descriptor, v.run, v)
      end
    end

    if propagate and parent then execAll(descriptor, parent, propagate) end
  end

  local file = function(file)
    busted.publish({ 'file', 'start' }, file.name)

    if busted.safe('file', file.run, file, true) then
      busted.execute(file)
    end

    busted.publish({ 'file', 'end' }, file.name)
  end

  local describe = function(describe)
    local parent = busted.context.parent(describe)

    busted.publish({ 'describe', 'start' }, describe, parent)

    if busted.safe('describe', describe.run, describe) then
      execAll('setup', describe)
      busted.execute(describe)
      dexecAll('teardown', describe)
    end

    busted.publish({ 'describe', 'end' }, describe, parent)
  end

  local it = function(it)
    local finally

    if not it.env then it.env = {} end

    it.env.finally = function(fn)
      finally = fn
    end

    local parent = busted.context.parent(it)

    execAll('before_each', parent, true)
    busted.publish({ 'test', 'start' }, it, parent)
    busted.publish({ 'test', 'end' }, it, parent, busted.safe('it', it.run, it))

    if finally then busted.safe('finally', finally, it) end

    dexecAll('after_each', parent, true)
  end

  local pending = function(pending)
    local trace = busted.getTrace(pending, 3)
    busted.publish({ 'pending' }, pending, busted.context.parent(pending), 'pending', trace)
  end

  local async = function()
    local parent = busted.context.get()
    if not parent.env then parent.env = {} end

    parent.env.done = require 'busted.done'.new()
  end

  busted.register('file', file)

  busted.register('describe', describe)
  busted.register('context', describe)

  busted.register('it', it)
  busted.register('pending', pending)

  busted.context.get().env.async = async

  busted.register('setup')
  busted.register('teardown')
  busted.register('before_each')
  busted.register('after_each')

  assert = require 'luassert'
  spy    = require 'luassert.spy'
  mock   = require 'luassert.mock'
  stub   = require 'luassert.stub'

  return busted
end
