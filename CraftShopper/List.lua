local _, ns = ...

-- Merging new reagents into a shopping list that is already there.
--
-- Auctionator's API has no "append one item" call: a shopping list is written
-- whole, by CreateShoppingList, which replaces whatever was there. So adding to
-- a list means reading it, merging, and writing all of it back -- and the merge
-- has to be careful, because everything else on that list belongs to the player
-- and they did not ask us to touch it.
--
-- Like Reagents.lua this file is pure: it works on plain tables and knows
-- nothing about Auctionator's string format. Shopping.lua does the encoding.

local list = {}
ns.list = list

local function trim(text)
  return (string.gsub(text, '^%s*(.-)%s*$', '%1'))
end

-- Two search terms are the same entry when they name the same item at the same
-- crafting quality. Quality is part of the key because tier 1 and tier 3 of a
-- reagent are genuinely different purchases, and folding them together would
-- buy the wrong one.
--
-- Case is ignored and surrounding quotes are stripped: Auctionator writes an
-- exact search as a quoted string, so "Copper Ore" and Copper Ore are the same
-- row wearing different clothes.
function list.Key(term)
  if type(term) ~= 'table' then
    return nil
  end

  local name = term.searchString
  if type(name) ~= 'string' then
    return nil
  end

  name = trim(name)
  name = string.gsub(name, '^"(.*)"$', '%1')
  name = string.lower(name)

  if name == '' then
    return nil
  end

  return name .. '\30' .. tostring(term.tier or '')
end

-- Merges additions into an existing list.
--
-- existing:  { { raw = "<auctionator search string>", term = { ... } }, ... }
-- additions: { { searchString = "...", quantity = n, ... }, ... }
--
-- Returns a new array of the same shape. An entry keeps its `raw` string when
-- nothing about it changed, and carries raw = nil when the caller has to encode
-- it. That distinction is the point of this function: a row the player wrote
-- themselves, with settings we do not model, must come back out byte for byte.
--
-- A row with no quantity counts as zero, so adding 20 to it produces 20. The
-- alternative -- leaving "any quantity" alone -- would mean the count the
-- player just asked for silently does not appear.
function list.Merge(existing, additions)
  local merged = {}
  local index = {}

  for _, entry in ipairs(existing or {}) do
    local copy = {
      raw = entry.raw,
      term = entry.term,
    }

    merged[#merged + 1] = copy

    local key = list.Key(entry.term)
    -- First occurrence wins. A list that already holds the same item twice is
    -- the player's business; we add to the first row rather than inventing a
    -- rule for which of their rows is the real one.
    if key and index[key] == nil then
      index[key] = #merged
    end
  end

  for _, addition in ipairs(additions or {}) do
    local key = list.Key(addition)

    if key then
      local at = index[key]

      if at then
        local target = merged[at]
        local term = {}

        for field, value in pairs(target.term or {}) do
          term[field] = value
        end

        term.quantity = (tonumber(term.quantity) or 0) + (tonumber(addition.quantity) or 0)

        merged[at] = { raw = nil, term = term }
      else
        local term = {}
        for field, value in pairs(addition) do
          term[field] = value
        end

        merged[#merged + 1] = { raw = nil, term = term }
        index[key] = #merged
      end
    end
  end

  return merged
end

-- Folds repeated items in a set of additions together before they reach a list.
-- Two slots of one recipe can call for the same item, and two clicks on two
-- recipes certainly can.
function list.Combine(additions)
  local result = {}
  local index = {}

  for _, addition in ipairs(additions or {}) do
    local key = list.Key(addition)

    if key then
      local at = index[key]

      if at then
        result[at].quantity = (tonumber(result[at].quantity) or 0) + (tonumber(addition.quantity) or 0)
      else
        local term = {}
        for field, value in pairs(addition) do
          term[field] = value
        end

        result[#result + 1] = term
        index[key] = #result
      end
    end
  end

  return result
end
