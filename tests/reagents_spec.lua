-- Runs the reagent maths outside the game, against hand-built schematics.
--
--   lua5.4 tests/reagents_spec.lua
--
-- Reagents.lua is the file that decides what ends up on the shopping list, and
-- it touches no frames and no globals, so it loads cleanly here. Compat.lua,
-- UI.lua and Core.lua need a real client.
--
-- The schematics below are shaped the way C_TradeSkillUI.GetRecipeSchematic
-- answers on Retail: a reagentSlotSchematics array whose entries carry a
-- reagentType, a quantityRequired, and a reagents array of one entry per
-- crafting-quality tier.

package.path = './CraftShopper/?.lua;' .. package.path

local ns = {}

loadfile('CraftShopper/Reagents.lua')('CraftShopper', ns)

local reagents = ns.reagents

-- Stand-ins, not the client's real numbers. A live 12.1.0 client reports
-- Enum.CraftingReagentType.Basic == 1, which is why Reagents.lua is handed the
-- value rather than hardcoding one: the commonly repeated 0 is wrong, and the
-- tests pass either way precisely because nothing here assumes a number.
local BASIC = 0
local OPTIONAL = 2

local failures = 0

local function check(description, expected, actual)
  if expected == actual then
    print(('  ok    %s'):format(description))
  else
    failures = failures + 1
    print(('  FAIL  %s -- expected %s, got %s'):format(description, tostring(expected), tostring(actual)))
  end
end

local function slot(reagentType, quantityRequired, ...)
  local ids = { ... }
  local entries = {}

  for _, id in ipairs(ids) do
    entries[#entries + 1] = { itemID = id }
  end

  return {
    reagentType = reagentType,
    quantityRequired = quantityRequired,
    required = reagentType == BASIC,
    reagents = entries,
  }
end

local function schematic(...)
  return { reagentSlotSchematics = { ... } }
end

-- Builds a countFn from a plain itemID -> count table.
local function stock(counts)
  return function(itemID)
    return counts[itemID] or 0
  end
end

local function byItemID(entries)
  local map = {}
  for _, entry in ipairs(entries) do
    map[entry.itemID] = entry
  end
  return map
end

--------------------------------------------------------------------------------
print('slot classification')
--------------------------------------------------------------------------------

check('a basic slot is basic', true, reagents.IsBasicSlot(slot(BASIC, 1, 100), BASIC))
check('an optional slot is not', false, reagents.IsBasicSlot(slot(OPTIONAL, 1, 100), BASIC))

-- Without the enum the `required` flag stands in, which is what the addon falls
-- back to if Enum.CraftingReagentType ever moves.
check('required stands in for a missing enum', true, reagents.IsBasicSlot(slot(BASIC, 1, 100), nil))
check('not-required stands in too', false, reagents.IsBasicSlot(slot(OPTIONAL, 1, 100), nil))

check('nil is not a slot', false, reagents.IsBasicSlot(nil, BASIC))

--------------------------------------------------------------------------------
print('collecting')
--------------------------------------------------------------------------------

local recipe = schematic(
  slot(BASIC, 3, 100),
  slot(BASIC, 2, 200, 201, 202),
  slot(OPTIONAL, 1, 300)
)

local collected = reagents.Collect(recipe, { basicType = BASIC })

check('optional slots are left out', 2, #collected)
check('first reagent', 100, collected[1].itemID)
check('per craft', 3, collected[1].perCraft)
check('need without a multiplier', 3, collected[1].need)

-- The shopping list gets the first quality tier; the others still count as
-- stock, which is why every ID is kept.
check('quality tiers are kept', 3, #collected[2].itemIDs)
check('the base tier is what gets bought', 200, collected[2].itemID)

collected = reagents.Collect(recipe, { basicType = BASIC, multiplier = 20 })
check('need with a multiplier', 60, collected[1].need)
check('second slot with a multiplier', 40, collected[2].need)

collected = reagents.Collect(recipe, { basicType = BASIC, multiplier = 0 })
check('a multiplier below one is one', 3, collected[1].need)

collected = reagents.Collect(recipe, { basicType = BASIC, multiplier = 2.7 })
check('a fractional multiplier is floored', 6, collected[1].need)

check('an empty schematic collects nothing', 0, #reagents.Collect({}, { basicType = BASIC }))
check('a nil schematic collects nothing', 0, #reagents.Collect(nil, { basicType = BASIC }))

-- A slot with no item IDs is not something to buy, whatever it claims to need.
check('a slot with no items is skipped', 0, #reagents.Collect(schematic(slot(BASIC, 5)), { basicType = BASIC }))

--------------------------------------------------------------------------------
print('subtracting what you own')
--------------------------------------------------------------------------------

collected = reagents.Collect(recipe, {
  basicType = BASIC,
  multiplier = 10,
  subtract = true,
  countFn = stock({ [100] = 12 }),
})

local map = byItemID(collected)
check('owned is counted', 12, map[100].have)
check('only the shortfall is missing', 18, map[100].missing)

-- Any quality of a reagent fills the slot, so all of them count towards what
-- the player already has.
check('every quality tier counts as stock', 0, map[200].have)

collected = reagents.Collect(recipe, {
  basicType = BASIC,
  multiplier = 10,
  subtract = true,
  countFn = stock({ [200] = 5, [201] = 4, [202] = 3 }),
})
map = byItemID(collected)
check('stock is summed across tiers', 12, map[200].have)
check('shortfall across tiers', 8, map[200].missing)

collected = reagents.Collect(recipe, {
  basicType = BASIC,
  subtract = true,
  countFn = stock({ [100] = 99, [200] = 99 }),
})
check('having more than enough is not a negative order', 0, byItemID(collected)[100].missing)

collected = reagents.Collect(recipe, {
  basicType = BASIC,
  multiplier = 10,
  subtract = false,
  countFn = stock({ [100] = 99 }),
})
check('subtract off means buy the lot', 30, byItemID(collected)[100].missing)

--------------------------------------------------------------------------------
print('one item in two slots')
--------------------------------------------------------------------------------

-- Folding has to happen before subtracting. Taking the player's stock off each
-- slot separately would under-buy by everything they own, once per slot -- a
-- quiet wrong answer, and the reason this case has a test of its own.
local doubled = schematic(
  slot(BASIC, 4, 100),
  slot(BASIC, 6, 100)
)

collected = reagents.Collect(doubled, {
  basicType = BASIC,
  subtract = true,
  countFn = stock({ [100] = 3 }),
})

check('the two slots are one entry', 1, #collected)
check('their quantities are summed', 10, collected[1].perCraft)
check('stock is taken off once, not twice', 7, collected[1].missing)

--------------------------------------------------------------------------------
print('filtering')
--------------------------------------------------------------------------------

collected = reagents.Collect(recipe, {
  basicType = BASIC,
  subtract = true,
  countFn = stock({ [100] = 99 }),
})

local missing = reagents.Missing(collected)
check('entries with nothing to buy are dropped', 1, #missing)
check('the remaining one is the right one', 200, missing[1].itemID)

check('nothing missing is an empty list', 0, #reagents.Missing(reagents.Collect(recipe, {
  basicType = BASIC,
  subtract = true,
  countFn = stock({ [100] = 99, [200] = 99 }),
})))

--------------------------------------------------------------------------------

if failures > 0 then
  print(('\n%d failure(s)'):format(failures))
  os.exit(1)
end

print('\nall good')
