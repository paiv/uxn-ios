local output = assert(io.open('.asma.tal', 'w'))
local process_subtree
process_subtree = function(items)
  local middle = math.floor(#items / 2 + 1.25)
  local node = items[middle]
  if not node then
    return 
  end
  node.left = process_subtree((function()
    local _accum_0 = { }
    local _len_0 = 1
    for i, item in ipairs(items) do
      if i < middle then
        _accum_0[_len_0] = item
        _len_0 = _len_0 + 1
      end
    end
    return _accum_0
  end)())
  node.right = process_subtree((function()
    local _accum_0 = { }
    local _len_0 = 1
    for i, item in ipairs(items) do
      if i > middle then
        _accum_0[_len_0] = item
        _len_0 = _len_0 + 1
      end
    end
    return _accum_0
  end)())
  return node
end
local process_tree
process_tree = function(items)
  local sorted_items
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #items do
      local item = items[_index_0]
      _accum_0[_len_0] = item
      _len_0 = _len_0 + 1
    end
    sorted_items = _accum_0
  end
  table.sort(sorted_items, function(a, b)
    return a.order < b.order
  end);
  (process_subtree(sorted_items)).label = '&_entry'
  for _index_0 = 1, #items do
    local item = items[_index_0]
    output:write(('\t%-11s %-10s %-12s %s%s\n'):format(item.label, item.left and item.left.ref or ' $2', (item.right and item.right.ref or ' $2') .. item.extra, item.key, item.rest))
  end
end
local parse_tree
parse_tree = function(it)
  local items = { }
  for l in it do
    if l == '' then
      process_tree(items)
      output:write('\n')
      return 
    end
    local item = {
      extra = ''
    }
    item.key, item.rest = l:match('^%s*%S+%s+%S+%s+%S+%s+(%S+)(.*)')
    if item.key:match('^%&') then
      item.extra = (' %s'):format(item.key)
      item.key, item.rest = item.rest:match('^%s+(%S+)(.*)')
    end
    if item.key:match('^%"') then
      item.order = item.key:sub(2)
    elseif item.key:match('^%x%x') then
      item.order = string.char(tonumber(item.key, 16))
    else
      error(('unknown key: %q'):format(item.key))
    end
    if item.order:match('^%a') then
      item.label = ('&%s'):format(item.order)
    elseif item.order:match('^.$') then
      item.label = ('&%x'):format(item.order:byte())
    else
      error(('unknown label: %q'):format(item.order))
    end
    item.ref = (':%s'):format(item.label)
    table.insert(items, item)
  end
end
local it = assert(io.lines('projects/library/asma.tal'))
local waiting_for_cut = true
for l in it do
  output:write(l)
  output:write('\n')
  if l:find('--- cut here ---', 1, true) then
    waiting_for_cut = false
  end
  if not waiting_for_cut and '@' == l:sub(1, 1) then
    parse_tree(it)
  end
end
output:close()
return os.execute('mv .asma.tal projects/library/asma.tal')
