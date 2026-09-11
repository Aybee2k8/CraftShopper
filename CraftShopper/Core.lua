local ADDON, ns = ...

local L = ns.L
local compat = ns.compat
local reagents = ns.reagents
local shopping = ns.shopping

local DEFAULTS = {
  -- The list Auctionator writes to. One fixed name rather than one per recipe:
  -- a shopping trip is a shopping trip, and twenty lists named after twenty
  -- recipes is a mess to clear up afterwards.
  listName = 'CraftShopper',

  subtractInventory = true,
  includeBank = true,
  -- How many crafts to buy for. Set in the box next to the button, kept here so
  -- it survives a relog -- a number you have to retype every session is a
  -- number you will forget to retype.
  craftCount = 1,

  useCraftCount = true,
  replaceList = false,
  announce = true,
  showButton = true,

  -- nil until the player drags the button, at which point UI.lua fills it in.
  point = nil,
}

local db
local core = {}
ns.core = core

local function say(message)
  print('|cff33ff99CraftShopper|r: ' .. message)
end

core.Say = say

local function onOffLabel(value)
  return value and L.SETTING_ON or L.SETTING_OFF
end

local function copyDefaults(target, defaults)
  for key, value in pairs(defaults) do
    if target[key] == nil and value ~= nil then
      if type(value) == 'table' then
        local copy = {}
        for i = 1, #value do
          copy[i] = value[i]
        end
        target[key] = copy
      else
        target[key] = value
      end
    end
  end
end

-- Bound on ADDON_LOADED rather than at parse time: the engine populates the
-- SavedVariables global after the Lua files are loaded, so a reference taken
-- any earlier would be to a table that gets replaced.
local function initDB()
  CraftShopperDB = CraftShopperDB or {}
  copyDefaults(CraftShopperDB, DEFAULTS)
  db = CraftShopperDB
end

-- The single way to read and write settings. The panel, the slash commands and
-- the button all go through here; a value written straight to the saved
-- variables from one of them would silently drift from the others.
function core.Get(key)
  if not db then
    return DEFAULTS[key]
  end
  return db[key]
end

function core.Set(key, value)
  if not db then
    return
  end

  db[key] = value

  if (key == 'showButton' or key == 'craftCount') and ns.ui then
    ns.ui.Refresh()
  end
end

function core.Defaults()
  return DEFAULTS
end

--------------------------------------------------------------------------------
-- The actual job
--------------------------------------------------------------------------------

-- Reads the open recipe and works out what it needs. Shared by Send and
-- Preview so that what you are shown is computed by the same code that does
-- the buying, and not by a second implementation that can disagree with it.
--
-- countOverride comes from `/cshop add 20` and wins over everything else; see
-- reagents.ResolveMultiplier for the rest of the order.
--
-- Returns nil plus a message to print when there is nothing to work with.
local function collectOpenRecipe(countOverride)
  local schematic, recipeName = compat.GetOpenRecipe()
  if not schematic then
    return nil, L.NO_RECIPE
  end

  recipeName = recipeName or '?'

  local multiplier = reagents.ResolveMultiplier(
    countOverride,
    compat.GetCraftCount(),
    core.Get('useCraftCount'),
    core.Get('craftCount')
  )

  local includeBank = core.Get('includeBank')

  local collected = reagents.Collect(schematic, {
    basicType = compat.BasicReagentType(),
    multiplier = multiplier,
    subtract = core.Get('subtractInventory'),
    countFn = function(itemID)
      return compat.GetItemCount(itemID, includeBank)
    end,
  })

  if #collected == 0 then
    return nil, L.NO_REAGENTS
  end

  return collected, nil, recipeName, multiplier
end

-- Prints the whole calculation without touching any shopping list: what the
-- recipe needs, what you are holding, what is left to buy.
--
-- This exists because "you already have every reagent" is an answer the player
-- cannot check. It is produced by subtracting a stock count they cannot see
-- from a requirement they did not state, and if either number is wrong the
-- addon looks broken rather than wrong. Showing the arithmetic is the
-- difference between a bug report and a guess.
function core.Preview(countOverride)
  local collected, problem, recipeName, multiplier = collectOpenRecipe(countOverride)
  if not collected then
    say(problem)
    return
  end

  local wanted = {}
  for _, entry in ipairs(collected) do
    wanted[#wanted + 1] = entry.itemID
  end

  compat.LoadItemNames(wanted, function(names)
    say(L.PREVIEW_HEADER:format(multiplier, recipeName))

    for _, entry in ipairs(collected) do
      print(L.PREVIEW_LINE:format(
        names[entry.itemID] or ('item:' .. tostring(entry.itemID)),
        entry.need,
        entry.have,
        entry.missing
      ))
    end

    print(L.PREVIEW_FOOTER:format(
      onOffLabel(core.Get('subtractInventory')),
      onOffLabel(core.Get('includeBank'))
    ))
  end)
end

-- Puts the reagents of the open recipe onto the shopping list.
--
-- Names are resolved asynchronously, so the work finishes inside a callback.
-- That is not an implementation detail that can be avoided: Auctionator
-- searches by item name, and an uncached reagent has no name yet. Writing the
-- list without waiting would drop exactly the reagents the player has never
-- owned -- which are the ones they are most likely to be shopping for.
function core.Send(countOverride)
  if not shopping.IsAvailable() then
    say(L.NO_AUCTIONATOR)
    return
  end

  local collected, problem, recipeName, multiplier = collectOpenRecipe(countOverride)
  if not collected then
    say(problem)
    return
  end

  local missing = reagents.Missing(collected)
  if #missing == 0 then
    say(L.NOTHING_MISSING:format(multiplier, recipeName))
    -- Naming the setting that produced this answer, and the command that shows
    -- its arithmetic, turns a dead end into something the player can act on.
    say(L.NOTHING_MISSING_HINT)
    return
  end

  local wanted = {}
  for _, entry in ipairs(missing) do
    wanted[#wanted + 1] = entry.itemID
  end

  compat.LoadItemNames(wanted, function(names)
    local additions = {}
    local lines = {}

    for _, entry in ipairs(missing) do
      local name = names[entry.itemID]
      if name then
        additions[#additions + 1] = shopping.BuildTerm(name, entry.missing)
        lines[#lines + 1] = L.ADDED_LINE:format(name, entry.missing, entry.need, entry.have)
      end
    end

    if #additions == 0 then
      say(L.NAMES_FAILED)
      return
    end

    local replace = core.Get('replaceList')
    local listName = core.Get('listName')

    local ok, err = shopping.Add(listName, additions, replace)
    if not ok then
      say(L.WRITE_FAILED:format(tostring(err)))
      return
    end

    if replace then
      say(L.REPLACED:format(listName, #additions, multiplier, recipeName))
    else
      say(L.ADDED:format(#additions, multiplier, recipeName, listName))
    end

    if core.Get('announce') then
      for _, line in ipairs(lines) do
        print(line)
      end
    end
  end)
end

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------

local function toggle(key, label)
  core.Set(key, not core.Get(key))
  say(L.SETTING_CHANGED:format(label, onOffLabel(core.Get(key))))
end

local function diag()
  say(L.DIAG_HEADER)

  local build = _G.GetBuildInfo and select(4, _G.GetBuildInfo()) or '?'

  -- Read from X-Interface, not Interface. GetAddOnMetadata only answers for a
  -- fixed set of fields plus custom X- ones, and Interface is not in that set:
  -- asking for it returns nil, which printed as "addon declares ?" on a live
  -- client and told nobody anything. The TOC therefore carries the number
  -- twice and CI asserts the two agree.
  local declared = '?'
  if _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata then
    declared = _G.C_AddOns.GetAddOnMetadata(ADDON, 'X-Interface') or '?'
  end
  print(L.DIAG_INTERFACE:format(tostring(build), tostring(declared)))

  -- Re-probed on every call rather than once at load: almost everything here
  -- only exists after Blizzard_Professions has loaded and a recipe is open, so
  -- a report taken at load time would say "missing" about things that are fine.
  wipe(compat.probes)
  compat.ProbeOptional()

  for _, entry in ipairs(compat.probes) do
    local status = entry.ok and L.DIAG_OK or L.DIAG_MISSING
    local detail = entry.detail and (' (' .. tostring(entry.detail) .. ')') or ''
    print(('  %s  %s%s'):format(status, entry.name, detail))
  end

  -- Without this, the one probe that legitimately reports missing most of the
  -- time reads as a fault. It is only answerable with a recipe on screen.
  if compat.GetActiveSchematicForm() == nil then
    print(L.DIAG_NO_RECIPE_HINT)
  end
end

local function help()
  say(L.SLASH_HELP_HEADER)
  for _, line in ipairs(L.SLASH_HELP) do
    print('  ' .. line)
  end
end

-- Exposed so the settings panel has something to fall back on when the Settings
-- API is not there: every setting the panel offers has a slash command.
core.Help = help

local function handleSlash(input)
  input = input or ''

  local command, rest = input:match('^%s*(%S*)%s*(.-)%s*$')
  command = (command or ''):lower()

  if command == '' or command == 'add' then
    core.Send(tonumber(rest))
  elseif command == 'preview' or command == 'show' then
    core.Preview(tonumber(rest))
  elseif command == 'count' then
    local value = tonumber(rest)
    if value and value >= 1 then
      core.Set('craftCount', math.floor(value))
    end
    say(L.COUNT_CHANGED:format(core.Get('craftCount')))
  elseif command == 'list' then
    if rest == '' then
      say(L.LIST_CHANGED:format(core.Get('listName')))
    else
      core.Set('listName', rest)
      say(L.LIST_CHANGED:format(rest))
    end
  elseif command == 'own' then
    toggle('subtractInventory', L.OPTIONS_SUBTRACT)
  elseif command == 'bank' then
    toggle('includeBank', L.OPTIONS_INCLUDE_BANK)
  elseif command == 'replace' then
    toggle('replaceList', L.OPTIONS_REPLACE)
  elseif command == 'button' then
    toggle('showButton', L.OPTIONS_SHOW_BUTTON)
  elseif command == 'reset' then
    core.Set('point', nil)
    if ns.ui then
      ns.ui.ResetPosition()
    end
    say(L.POSITION_RESET)
  elseif command == 'diag' then
    diag()
  elseif command == 'options' or command == 'config' then
    if ns.options then
      ns.options.Open()
    end
  else
    help()
  end
end

SLASH_CRAFTSHOPPER1 = '/craftshopper'
SLASH_CRAFTSHOPPER2 = '/cshop'
SlashCmdList['CRAFTSHOPPER'] = handleSlash

function CraftShopper_OnAddonCompartmentClick()
  if ns.options then
    ns.options.Open()
  end
end

--------------------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------------------

-- Lua errors are hidden by default in Retail, so a failure during setup would
-- otherwise leave the addon doing nothing with nothing on screen to say why.
local function guard(what, fn)
  local ok, err = pcall(fn)
  if not ok then
    say(what .. ': ' .. tostring(err))
  end
end

local frame = CreateFrame('Frame')

compat.RegisterEvent(frame, 'ADDON_LOADED')
compat.RegisterEvent(frame, 'PLAYER_LOGIN')

frame:SetScript('OnEvent', function(_, event, arg1)
  if event == 'ADDON_LOADED' then
    if arg1 == ADDON then
      initDB()
      guard('options', function()
        if ns.options then
          ns.options.Build()
        end
      end)
    elseif arg1 == 'Blizzard_Professions' then
      -- The Professions UI is load on demand: the frames the button anchors to
      -- do not exist until the player opens a profession for the first time.
      guard('button', function()
        if ns.ui then
          ns.ui.Attach()
        end
      end)
    end
  elseif event == 'PLAYER_LOGIN' then
    -- Covers the case where Blizzard_Professions was already loaded before we
    -- were -- another addon can pull it in early.
    if _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded and _G.C_AddOns.IsAddOnLoaded('Blizzard_Professions') then
      guard('button', function()
        if ns.ui then
          ns.ui.Attach()
        end
      end)
    end
  end
end)
