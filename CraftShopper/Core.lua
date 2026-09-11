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

  if key == 'showButton' and ns.ui then
    ns.ui.Refresh()
  end
end

function core.Defaults()
  return DEFAULTS
end

--------------------------------------------------------------------------------
-- The actual job
--------------------------------------------------------------------------------

-- Puts the reagents of the open recipe onto the shopping list.
--
-- countOverride comes from `/cshop add 20` and wins over everything; otherwise
-- the craft count dialled up in the profession window is used, if the setting
-- allows it and the field could be read at all.
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

  local schematic, recipeName = compat.GetOpenRecipe()
  if not schematic then
    say(L.NO_RECIPE)
    return
  end

  recipeName = recipeName or '?'

  local multiplier = tonumber(countOverride)
  if not multiplier and core.Get('useCraftCount') then
    multiplier = compat.GetCraftCount()
  end
  multiplier = multiplier or 1

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
    say(L.NO_REAGENTS)
    return
  end

  local missing = reagents.Missing(collected)
  if #missing == 0 then
    say(L.NOTHING_MISSING:format(multiplier, recipeName))
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
        lines[#lines + 1] = L.ADDED_LINE:format(name, entry.missing)
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

local function onOff(value)
  return value and L.SETTING_ON or L.SETTING_OFF
end

local function toggle(key, label)
  core.Set(key, not core.Get(key))
  say(L.SETTING_CHANGED:format(label, onOff(core.Get(key))))
end

local function diag()
  say(L.DIAG_HEADER)

  local build = _G.GetBuildInfo and select(4, _G.GetBuildInfo()) or '?'
  local declared = '?'
  if _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata then
    declared = _G.C_AddOns.GetAddOnMetadata(ADDON, 'Interface') or '?'
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
