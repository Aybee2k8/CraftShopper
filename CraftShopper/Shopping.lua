local _, ns = ...

local compat = ns.compat
local list = ns.list

-- The bridge to Auctionator.
--
-- Auctionator publishes a versioned external API and says plainly that calling
-- anything else is unsupported and may break without warning. So this file
-- talks to Auctionator.API.v1 and to nothing else -- no reaching into
-- Auctionator.Shopping.ListManager, however convenient that would be.
--
-- Every call is wrapped: the API reports problems by raising, not by returning,
-- and an unguarded raise from a button click is a Lua error on the player's
-- screen. Errors are turned back into strings the caller can print.

local shopping = {}
ns.shopping = shopping

-- Auctionator's API takes a caller ID, which it puts into any error message so
-- the player knows which addon to complain to. That is us.
local CALLER_ID = 'CraftShopper'

local function api()
  local v1 = compat.Reach('Auctionator.API.v1')
  if type(v1) ~= 'table' then
    return nil
  end
  return v1
end

function shopping.IsAvailable()
  local v1 = api()

  return v1 ~= nil
    and type(v1.CreateShoppingList) == 'function'
    and type(v1.ConvertToSearchString) == 'function'
end

-- `;` separates the fields of an advanced search string and `^` separates
-- stored searches, so neither can appear inside one. No item name contains
-- either, but a name is client data and this is cheaper than finding out.
local function sanitize(name)
  return (string.gsub(name, '[;^]', ' '))
end

-- A search term for one reagent: an exact name match, with the count as the
-- quantity Auctionator shows next to the row.
function shopping.BuildTerm(itemName, quantity)
  return {
    searchString = sanitize(itemName),
    isExact = true,
    categoryKey = '',
    quantity = quantity,
  }
end

-- Reads a shopping list into entries List.Merge understands.
--
-- A list that does not exist is not an error here: it is the normal state
-- before the first click, and the answer is an empty list. Each row keeps its
-- original string alongside the parsed term so that rows we do not touch go
-- back exactly as they came.
function shopping.Read(listName)
  local v1 = api()
  if not v1 or type(v1.GetShoppingListItems) ~= 'function' then
    return {}
  end

  local ok, items = pcall(v1.GetShoppingListItems, CALLER_ID, listName)
  if not ok or type(items) ~= 'table' then
    return {}
  end

  local entries = {}

  for _, raw in ipairs(items) do
    if type(raw) == 'string' then
      local term

      if type(v1.ConvertFromSearchString) == 'function' then
        local parsed
        ok, parsed = pcall(v1.ConvertFromSearchString, CALLER_ID, raw)
        if ok and type(parsed) == 'table' then
          term = parsed
        end
      end

      -- An unparseable row still has to survive the round trip, so it is kept
      -- with its raw string and no term. List.Key returns nil for it, which
      -- means nothing will ever be merged into it -- correct: we do not know
      -- what it is.
      entries[#entries + 1] = { raw = raw, term = term }
    end
  end

  return entries
end

-- Writes entries back as the whole list.
--
-- Returns true, or false plus a message. CreateShoppingList replaces a list of
-- the same name, which is exactly what a read-merge-write needs, but it does
-- mean a failure part way through leaves the old list intact rather than a
-- half-written one -- so encoding is done for every row before anything is
-- sent.
function shopping.Write(listName, entries)
  local v1 = api()
  if not shopping.IsAvailable() then
    return false, 'Auctionator.API.v1 is not available'
  end

  local strings = {}

  for _, entry in ipairs(entries) do
    if entry.raw then
      strings[#strings + 1] = entry.raw
    elseif type(entry.term) == 'table' then
      local ok, encoded = pcall(v1.ConvertToSearchString, CALLER_ID, entry.term)
      if not ok then
        return false, tostring(encoded)
      end
      strings[#strings + 1] = encoded
    end
  end

  local ok, err = pcall(v1.CreateShoppingList, CALLER_ID, listName, strings)
  if not ok then
    return false, tostring(err)
  end

  return true
end

-- Adds terms to a named list, or replaces the list with them.
--
-- The read-merge-write is deliberately not conditional on the list existing:
-- Read answers with an empty list either way, and CreateShoppingList makes one.
function shopping.Add(listName, additions, replace)
  if not shopping.IsAvailable() then
    return false, 'Auctionator.API.v1 is not available'
  end

  local combined = list.Combine(additions)

  local entries
  if replace then
    entries = {}
    for _, term in ipairs(combined) do
      entries[#entries + 1] = { raw = nil, term = term }
    end
  else
    entries = list.Merge(shopping.Read(listName), combined)
  end

  return shopping.Write(listName, entries)
end
