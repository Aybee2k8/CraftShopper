local _, ns = ...

-- Every client-API difference and every piece of Blizzard UI this addon reaches
-- into lives here, so the rest of the addon is written against one small,
-- stable surface.
--
-- Three things drive this file:
--
--   * The Professions UI is a load-on-demand addon, and the widgets inside it
--     are private frame names that have been renamed more than once across
--     expansions. Every one of them is resolved lazily and defensively; a
--     rename must degrade to "no recipe found", never to a Lua error.
--   * Patch 12.0 moved a number of globals into C_* namespaces, and which
--     spelling a given build answers to is not something we can know ahead of
--     time.
--   * Item names are not guaranteed to be in the client's cache when we ask.
--     Auctionator searches by name, so a missing name is not a cosmetic
--     problem -- it is a reagent silently dropped from the list.
--
-- Everything probed here is recorded, and /cshop diag prints the record. That
-- report is the fastest way to find out what a new build actually changed.

local compat = {}
ns.compat = compat

local probes = {}
compat.probes = probes

local function probe(name, ok, detail)
  probes[#probes + 1] = { name = name, ok = ok and true or false, detail = detail }
end

compat.Probe = probe

--------------------------------------------------------------------------------
-- Small helpers
--------------------------------------------------------------------------------

-- Calls a method on an object and returns its first two results, or nil if the
-- object, the method, or the call itself did not hold up. Used for every
-- Blizzard widget call: all of them are on frames we do not own and cannot
-- rely on.
local function tryCall(object, method, ...)
  if type(object) ~= 'table' or type(object[method]) ~= 'function' then
    return nil
  end

  local ok, first, second = pcall(object[method], object, ...)
  if not ok then
    return nil
  end

  return first, second
end

compat.TryCall = tryCall

-- Walks a dotted path from _G, stopping at the first missing link. Returns nil
-- rather than raising, so a renamed frame is a normal outcome and not a crash.
local function reach(path)
  local node = _G

  for segment in string.gmatch(path, '[^%.]+') do
    if type(node) ~= 'table' then
      return nil
    end

    local ok, value = pcall(function()
      return node[segment]
    end)

    if not ok then
      return nil
    end

    node = value
  end

  return node
end

compat.Reach = reach

--------------------------------------------------------------------------------
-- Items
--------------------------------------------------------------------------------

-- How many of an item the player holds.
--
-- includeBank widens the count to the bank, the reagent bank and the warband
-- bank. Those arguments are simply ignored by clients that do not have them,
-- which is why they are passed unconditionally rather than probed for.
function compat.GetItemCount(itemID, includeBank)
  local fn = (_G.C_Item and _G.C_Item.GetItemCount) or _G.GetItemCount
  if type(fn) ~= 'function' then
    return 0
  end

  local ok, count = pcall(fn, itemID, includeBank, false, includeBank, includeBank)
  if not ok or type(count) ~= 'number' then
    return 0
  end

  return count
end

-- The item's name if the client already has it cached, nil otherwise.
function compat.GetItemName(itemID)
  local fn = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
  if type(fn) ~= 'function' then
    return nil
  end

  local ok, name = pcall(fn, itemID)
  if ok and type(name) == 'string' and name ~= '' then
    return name
  end

  return nil
end

-- Nudges the client into fetching an item we do not have a name for yet. The
-- call itself answers nothing; it is the continuation below that tells us when
-- the data arrived.
local function requestItemData(itemID)
  local fn = _G.C_Item and _G.C_Item.RequestLoadItemDataByID
  if type(fn) == 'function' then
    pcall(fn, itemID)
  end
end

-- Resolves names for every item ID given, then calls callback(namesByID).
--
-- Uncached items are requested and waited on. The wait has a hard backstop: an
-- item that never resolves would otherwise leave the callback pending forever
-- and the button looking broken with nothing in chat to explain it. Names that
-- did not arrive are simply absent from the table, and the caller decides what
-- to say about them.
function compat.LoadItemNames(itemIDs, callback)
  local names = {}
  local pending = {}

  for _, itemID in ipairs(itemIDs) do
    if names[itemID] == nil then
      local name = compat.GetItemName(itemID)
      if name then
        names[itemID] = name
      else
        pending[itemID] = true
      end
    end
  end

  local waiting = 0
  for _ in pairs(pending) do
    waiting = waiting + 1
  end

  if waiting == 0 then
    callback(names)
    return
  end

  local finished = false

  local function finish()
    if finished then
      return
    end
    finished = true
    callback(names)
  end

  local function resolved(itemID)
    if not pending[itemID] then
      return
    end
    pending[itemID] = nil

    names[itemID] = compat.GetItemName(itemID) or names[itemID]

    waiting = waiting - 1
    if waiting <= 0 then
      finish()
    end
  end

  for itemID in pairs(pending) do
    requestItemData(itemID)

    local started = false

    if type(_G.Item) == 'table' and type(_G.Item.CreateFromItemID) == 'function' then
      local ok, item = pcall(_G.Item.CreateFromItemID, itemID)
      if ok and type(item) == 'table' and type(item.ContinueOnItemLoad) == 'function' then
        started = pcall(item.ContinueOnItemLoad, item, function()
          resolved(itemID)
        end)
      end
    end

    if not started then
      -- No Item mixin: the request above is still in flight, so the backstop
      -- below is what completes this one.
      probe('Item:CreateFromItemID', false)
    end
  end

  if type(_G.C_Timer) == 'table' and type(_G.C_Timer.After) == 'function' then
    pcall(_G.C_Timer.After, 3, function()
      -- Sweep once more before giving up: an item can finish loading without
      -- the continuation firing if it was already resolving when we asked.
      for itemID in pairs(pending) do
        names[itemID] = compat.GetItemName(itemID) or names[itemID]
      end
      finish()
    end)
  end
end

--------------------------------------------------------------------------------
-- Professions UI
--------------------------------------------------------------------------------

-- Reagent slots come in kinds, and only the basic ones are reagents you have to
-- supply for every craft. Optional, finishing and modifying reagents are
-- choices, not requirements, and putting them on a shopping list would mean
-- buying things the player never asked for.
--
-- The enum is read by name so a renumbering does not silently change which
-- slots we pick up. If it is gone entirely, the slot's own `required` flag is
-- the fallback -- coarser, but it errs towards the same set.
function compat.BasicReagentType()
  local value = reach('Enum.CraftingReagentType.Basic')
  if type(value) == 'number' then
    return value
  end
  return nil
end

-- The schematic forms that can hold the recipe the player is looking at. Order
-- matters: the crafting page is checked first because that is where a player
-- browsing recipes actually is, and an order view left open behind it should
-- not win.
local SCHEMATIC_FORMS = {
  'ProfessionsFrame.CraftingPage.SchematicForm',
  'ProfessionsFrame.OrdersPage.OrderView.SchematicForm',
  'ProfessionsCustomerOrdersFrame.Form',
}

local function formIsVisible(form)
  local shown = tryCall(form, 'IsVisible')
  return shown == true
end

-- The schematic form the player is currently looking at, or nil.
function compat.GetActiveSchematicForm()
  for _, path in ipairs(SCHEMATIC_FORMS) do
    local form = reach(path)
    if type(form) == 'table' and formIsVisible(form) then
      return form, path
    end
  end

  return nil
end

-- The recipe schematic for the open recipe, plus its name and ID.
--
-- The transaction is preferred over a fresh lookup because it is the object the
-- form itself is working from: it already carries the recipe level and recraft
-- state, which a bare GetRecipeSchematic call would have to guess at.
function compat.GetOpenRecipe()
  local form = compat.GetActiveSchematicForm()
  if not form then
    return nil
  end

  local schematic = tryCall(form.transaction, 'GetRecipeSchematic')

  if type(schematic) ~= 'table' then
    local info = tryCall(form, 'GetRecipeInfo') or form.currentRecipeInfo
    local recipeID = type(info) == 'table' and info.recipeID or nil

    if recipeID and type(reach('C_TradeSkillUI.GetRecipeSchematic')) == 'function' then
      local ok, fetched = pcall(_G.C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
      if ok and type(fetched) == 'table' then
        schematic = fetched
      end
    end
  end

  if type(schematic) ~= 'table' then
    return nil
  end

  local name = schematic.name
  if type(name) ~= 'string' or name == '' then
    local info = tryCall(form, 'GetRecipeInfo') or form.currentRecipeInfo
    name = type(info) == 'table' and info.name or nil
  end

  return schematic, name, schematic.recipeID
end

-- How many crafts the player has dialled up in the profession window.
--
-- Returns nil when the field is not there or holds nothing usable, so the
-- caller can tell "the player asked for one" apart from "we could not read the
-- field" and fall back to its own default rather than to a silent 1.
function compat.GetCraftCount()
  local box = reach('ProfessionsFrame.CraftingPage.CreateMultipleInputBox')
  local value = tryCall(box, 'GetValue')

  if type(value) ~= 'number' then
    return nil
  end

  value = math.floor(value)
  if value < 1 then
    return nil
  end

  return value
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

-- RegisterEvent throws on an unknown event name, and these calls happen at load
-- time -- one renamed event would stop the whole addon from loading. Each
-- registration is therefore isolated, and failures are reported rather than
-- fatal.
function compat.RegisterEvent(frame, event)
  local ok = pcall(frame.RegisterEvent, frame, event)
  probe('event ' .. event, ok)
  return ok
end

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

-- Records the state of everything we depend on but do not wrap, so /cshop diag
-- covers it too. Run after opening a profession window: most of these only
-- exist once Blizzard_Professions has loaded.
function compat.ProbeOptional()
  for _, name in ipairs({
    'CreateShoppingList',
    'GetShoppingListItems',
    'ConvertToSearchString',
    'ConvertFromSearchString',
  }) do
    local path = 'Auctionator.API.v1.' .. name
    probe(path, type(reach(path)) == 'function')
  end

  probe('C_TradeSkillUI.GetRecipeSchematic', type(reach('C_TradeSkillUI.GetRecipeSchematic')) == 'function')
  probe('Enum.CraftingReagentType.Basic', compat.BasicReagentType() ~= nil, tostring(compat.BasicReagentType()))
  probe('ProfessionsFrame', reach('ProfessionsFrame') ~= nil)

  local _, path = compat.GetActiveSchematicForm()
  probe('a schematic form is open', path ~= nil, path)

  probe('CreateMultipleInputBox', reach('ProfessionsFrame.CraftingPage.CreateMultipleInputBox') ~= nil)
  probe('craft count readable', compat.GetCraftCount() ~= nil, tostring(compat.GetCraftCount()))

  probe('C_Item.GetItemCount', type(reach('C_Item.GetItemCount')) == 'function')
  probe('C_Item.GetItemInfo', type(reach('C_Item.GetItemInfo')) == 'function')
  probe('Item mixin', type(reach('Item.CreateFromItemID')) == 'function')
end
