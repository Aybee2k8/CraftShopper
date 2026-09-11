-- Runs the shopping-list merge outside the game.
--
--   lua5.4 tests/list_spec.lua
--
-- This is the part of the addon that touches data belonging to the player.
-- Auctionator has no "append one item" call, so adding to a list means reading
-- it, merging, and writing all of it back -- and a mistake here does not throw
-- an error, it quietly rewrites rows somebody else put there. Hence the tests.

package.path = './CraftShopper/?.lua;' .. package.path

local ns = {}

loadfile('CraftShopper/List.lua')('CraftShopper', ns)

local list = ns.list

local failures = 0

local function check(description, expected, actual)
  if expected == actual then
    print(('  ok    %s'):format(description))
  else
    failures = failures + 1
    print(('  FAIL  %s -- expected %s, got %s'):format(description, tostring(expected), tostring(actual)))
  end
end

local function existing(...)
  local entries = {}

  for _, spec in ipairs({ ... }) do
    entries[#entries + 1] = {
      raw = spec.raw,
      term = spec.term,
    }
  end

  return entries
end

local function term(name, quantity, tier)
  return { searchString = name, quantity = quantity, tier = tier, isExact = true }
end

--------------------------------------------------------------------------------
print('keys')
--------------------------------------------------------------------------------

check('case does not matter', list.Key(term('Copper Ore')), list.Key(term('copper ore')))
check('surrounding space does not matter', list.Key(term('Copper Ore')), list.Key(term('  Copper Ore  ')))

-- Auctionator writes an exact search as a quoted string, so the same row can
-- come back wearing quotes it did not go in with.
check('quotes do not matter', list.Key(term('Copper Ore')), list.Key(term('"Copper Ore"')))

check('a different item is a different key', true, list.Key(term('Copper Ore')) ~= list.Key(term('Tin Ore')))

-- Tier 1 and tier 3 of a reagent are genuinely different purchases.
check('quality is part of the key', true, list.Key(term('Ore', 1, 1)) ~= list.Key(term('Ore', 1, 3)))

check('an empty name has no key', nil, list.Key(term('')))
check('a missing name has no key', nil, list.Key({}))
check('a non-table has no key', nil, list.Key('Copper Ore'))

--------------------------------------------------------------------------------
print('merging into an empty list')
--------------------------------------------------------------------------------

local merged = list.Merge({}, { term('Copper Ore', 20) })

check('one entry', 1, #merged)
check('it needs encoding', nil, merged[1].raw)
check('quantity carried over', 20, merged[1].term.quantity)
check('exactness carried over', true, merged[1].term.isExact)

check('nothing in, nothing out', 0, #list.Merge({}, {}))
check('nil arguments are survivable', 0, #list.Merge(nil, nil))

--------------------------------------------------------------------------------
print('merging into rows that are already there')
--------------------------------------------------------------------------------

local player = existing(
  { raw = '"Copper Ore";;;;;;;;;;;#;;5', term = term('Copper Ore', 5) },
  { raw = '"Linen Cloth";;;;;;;;;;;#;;', term = term('Linen Cloth', nil) },
  { raw = 'something the player typed', term = { searchString = 'something the player typed' } }
)

merged = list.Merge(player, { term('Copper Ore', 20) })

check('the list does not grow', 3, #merged)
check('quantities are summed', 25, merged[1].term.quantity)
check('the changed row is re-encoded', nil, merged[1].raw)

-- The whole point of keeping `raw`: a row we did not touch has to come back out
-- byte for byte, including settings this addon does not model.
check('untouched rows keep their string', '"Linen Cloth";;;;;;;;;;;#;;', merged[2].raw)
check('the players own row is untouched', 'something the player typed', merged[3].raw)

-- A row with no quantity means "any". Leaving it alone would mean the count the
-- player just asked for silently does not appear anywhere.
merged = list.Merge(player, { term('Linen Cloth', 40) })
check('no quantity counts as zero', 40, merged[2].term.quantity)

merged = list.Merge(player, { term('Iron Ore', 12) })
check('a new item is appended', 4, #merged)
check('appended at the end', 'Iron Ore', merged[4].term.searchString)
check('existing rows are still untouched', '"Copper Ore";;;;;;;;;;;#;;5', merged[1].raw)

-- Merging must not mutate what it was handed: the caller still needs the
-- original if the write to Auctionator fails.
check('the input list is not mutated', 5, player[1].term.quantity)

--------------------------------------------------------------------------------
print('rows we cannot read')
--------------------------------------------------------------------------------

local unparsed = existing({ raw = 'garbled', term = nil })

merged = list.Merge(unparsed, { term('Copper Ore', 3) })
check('an unreadable row survives', 'garbled', merged[1].raw)
check('and nothing is merged into it', 2, #merged)

--------------------------------------------------------------------------------
print('combining before merging')
--------------------------------------------------------------------------------

local combined = list.Combine({
  term('Copper Ore', 10),
  term('Tin Ore', 4),
  term('copper ore', 5),
})

check('repeats fold together', 2, #combined)
check('their quantities are summed', 15, combined[1].quantity)
check('the first spelling wins', 'Copper Ore', combined[1].searchString)
check('order is otherwise kept', 'Tin Ore', combined[2].searchString)

check('nameless additions are dropped', 0, #list.Combine({ { quantity = 5 } }))
check('nil is survivable', 0, #list.Combine(nil))

--------------------------------------------------------------------------------
print('a list that already repeats itself')
--------------------------------------------------------------------------------

-- Two rows for one item is the player's business. We add to the first rather
-- than inventing a rule for which of their rows is the real one.
local repeated = existing(
  { raw = 'a', term = term('Copper Ore', 1) },
  { raw = 'b', term = term('Copper Ore', 2) }
)

merged = list.Merge(repeated, { term('Copper Ore', 10) })
check('still two rows', 2, #merged)
check('the first one grew', 11, merged[1].term.quantity)
check('the second is untouched', 'b', merged[2].raw)

--------------------------------------------------------------------------------

if failures > 0 then
  print(('\n%d failure(s)'):format(failures))
  os.exit(1)
end

print('\nall good')
