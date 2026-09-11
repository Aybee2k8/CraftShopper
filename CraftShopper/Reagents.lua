local _, ns = ...

-- Turns a recipe schematic into the list of things to buy.
--
-- This file touches no frames and no globals, which is what makes it the one
-- piece of the addon the test harness can run. Everything the client would
-- normally answer -- how many of an item you hold, which reagent type counts as
-- basic -- is passed in. Logic that lives anywhere else is logic that cannot be
-- tested, so keep it here.

local reagents = {}
ns.reagents = reagents

-- A slot counts as basic when the client's own enum says so. Where the enum is
-- missing the slot's `required` flag stands in: coarser, but it errs towards
-- the same set rather than towards buying optional reagents nobody asked for.
function reagents.IsBasicSlot(slot, basicType)
  if type(slot) ~= 'table' then
    return false
  end

  if basicType ~= nil and slot.reagentType ~= nil then
    return slot.reagentType == basicType
  end

  return slot.required == true
end

-- The item IDs that can fill a slot, in the client's own order.
--
-- A slot with several entries is a reagent that comes in quality tiers, and any
-- one of them fills it. All of them are returned: the first is what goes on the
-- shopping list, and the rest still count towards what the player already owns.
function reagents.SlotItemIDs(slot)
  local ids = {}

  if type(slot) ~= 'table' or type(slot.reagents) ~= 'table' then
    return ids
  end

  for _, reagent in ipairs(slot.reagents) do
    if type(reagent) == 'table' and type(reagent.itemID) == 'number' then
      ids[#ids + 1] = reagent.itemID
    end
  end

  return ids
end

local function slotKey(itemIDs)
  return table.concat(itemIDs, ':')
end

-- Collects what a craft needs.
--
-- opts:
--   basicType  number|nil  Enum.CraftingReagentType.Basic, when the client has it
--   multiplier number      how many crafts (defaults to 1)
--   subtract   boolean     take what the player already owns off the total
--   countFn    function    countFn(itemID) -> number, how many are owned
--
-- Returns an array of entries in schematic order:
--   { itemIDs = { ... }, itemID = first, perCraft = n, need = n, have = n, missing = n }
--
-- Slots that share the same set of item IDs are folded into one entry before
-- anything is subtracted. Doing it the other way round would take the player's
-- stock off each slot separately and under-buy by everything they own, once per
-- slot -- a quiet wrong answer, which is worse than a loud one.
function reagents.Collect(schematic, opts)
  opts = opts or {}

  local multiplier = tonumber(opts.multiplier) or 1
  if multiplier < 1 then
    multiplier = 1
  end
  multiplier = math.floor(multiplier)

  local entries = {}
  local byKey = {}

  local slots = type(schematic) == 'table' and schematic.reagentSlotSchematics or nil
  if type(slots) ~= 'table' then
    return entries
  end

  for _, slot in ipairs(slots) do
    if reagents.IsBasicSlot(slot, opts.basicType) then
      local itemIDs = reagents.SlotItemIDs(slot)
      local perCraft = tonumber(slot.quantityRequired) or 0

      if #itemIDs > 0 and perCraft > 0 then
        local key = slotKey(itemIDs)
        local entry = byKey[key]

        if entry then
          entry.perCraft = entry.perCraft + perCraft
        else
          entry = {
            itemIDs = itemIDs,
            itemID = itemIDs[1],
            perCraft = perCraft,
          }
          byKey[key] = entry
          entries[#entries + 1] = entry
        end
      end
    end
  end

  local countFn = opts.countFn

  for _, entry in ipairs(entries) do
    entry.need = entry.perCraft * multiplier
    entry.have = 0

    if opts.subtract and type(countFn) == 'function' then
      for _, itemID in ipairs(entry.itemIDs) do
        entry.have = entry.have + (tonumber(countFn(itemID)) or 0)
      end
    end

    entry.missing = entry.need - entry.have
    if entry.missing < 0 then
      entry.missing = 0
    end
  end

  return entries
end

-- Drops the entries there is nothing left to buy for. Kept separate from
-- Collect so a caller that wants to show the full picture -- need, have,
-- missing -- still can.
function reagents.Missing(entries)
  local result = {}

  for _, entry in ipairs(entries) do
    if entry.missing and entry.missing > 0 then
      result[#result + 1] = entry
    end
  end

  return result
end
