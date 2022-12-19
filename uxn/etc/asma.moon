--
-- Asma tree helper script
--
-- This script balances the trees at the end of projects/library/asma.tal.
--
-- To run, you need Lua or LuaJIT, and just run etc/asma.lua from the top
-- directory of Uxn's git repository:
--
--     lua etc/asma.lua
--
-- This file is written in MoonScript, which is a language that compiles to
-- Lua, the same way as e.g. CoffeeScript compiles to JavaScript. Since
-- installing MoonScript has more dependencies than Lua, the compiled
-- etc/asma.lua is kept in Uxn's repository and will be kept updated as this
-- file changes.
--

output = assert io.open '.asma.tal', 'w'

process_subtree = (items) ->
    middle = math.floor #items / 2 + 1.25
    node = items[middle]
    if not node
        return
    node.left = process_subtree [ item for i, item in ipairs items when i < middle ]
    node.right = process_subtree [ item for i, item in ipairs items when i > middle ]
    node

process_tree = (items) ->
    sorted_items = [ item for item in *items ]
    table.sort sorted_items, (a, b) -> a.order < b.order
    (process_subtree sorted_items).label = '&_entry'
    for item in *items
        output\write '\t%-11s %-10s %-12s %s%s\n'\format item.label, item.left and item.left.ref or ' $2', (item.right and item.right.ref or ' $2') .. item.extra, item.key, item.rest

parse_tree = (it) ->
    items = {}
    for l in it
        if l == ''
            process_tree items
            output\write '\n'
            return
        item = { extra: '' }
        item.key, item.rest = l\match '^%s*%S+%s+%S+%s+%S+%s+(%S+)(.*)'
        if item.key\match '^%&'
            item.extra = ' %s'\format item.key
            item.key, item.rest = item.rest\match '^%s+(%S+)(.*)'
        if item.key\match '^%"'
            item.order = item.key\sub 2
        elseif item.key\match '^%x%x'
            item.order = string.char tonumber item.key, 16
        else
            error 'unknown key: %q'\format item.key
        if item.order\match '^%a'
            item.label = '&%s'\format item.order
        elseif item.order\match '^.$'
            item.label = '&%x'\format item.order\byte!
        else
            error 'unknown label: %q'\format item.order
        item.ref = ':%s'\format item.label
        table.insert items, item

it = assert io.lines 'projects/library/asma.tal'
waiting_for_cut = true
for l in it
    output\write l
    output\write '\n'
    if l\find '--- cut here ---', 1, true
        waiting_for_cut = false
    if not waiting_for_cut and '@' == l\sub 1, 1
        parse_tree it
output\close!
os.execute 'mv .asma.tal projects/library/asma.tal'

