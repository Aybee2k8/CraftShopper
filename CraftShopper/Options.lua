local _, ns = ...

local L = ns.L

-- The settings panel.
--
-- Built from primitives and three long-lived templates rather than from the
-- Settings API's generated controls. The generated ones are tidier, but their
-- initializer shapes have changed more than once and a mismatch is a hard error
-- at construction time -- which, with Lua errors hidden by default, shows up as
-- a settings category that simply is not there.
--
-- Every control reads and writes through ns.core, never through the saved
-- variables directly, so the panel and the slash commands cannot drift apart.

local options = {}
ns.options = options

local panel, category

local function core()
  return ns.core
end

local function checkbox(parent, label, y, key)
  local button = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
  button:SetPoint('TOPLEFT', 16, y)
  button:SetSize(24, 24)

  -- The templates expose their label FontString under different names across
  -- versions, so the label is ours: one fewer thing that can silently be nil.
  local text = button:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
  text:SetPoint('LEFT', button, 'RIGHT', 4, 0)
  text:SetText(label)

  button:SetScript('OnShow', function(self)
    self:SetChecked(core() and core().Get(key) and true or false)
  end)

  button:SetScript('OnClick', function(self)
    if core() then
      core().Set(key, self:GetChecked() and true or false)
    end
  end)

  return button, y - 28
end

local function listNameBox(parent, y)
  local label = parent:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  label:SetPoint('TOPLEFT', 18, y)
  label:SetText(L.OPTIONS_LIST_NAME)

  local box = CreateFrame('EditBox', nil, parent, 'InputBoxTemplate')
  box:SetPoint('TOPLEFT', 22, y - 18)
  box:SetSize(220, 22)
  box:SetAutoFocus(false)
  box:SetMaxLetters(64)

  local function commit(self)
    local value = (self:GetText() or ''):match('^%s*(.-)%s*$')

    if value == '' then
      value = core() and core().Defaults().listName or 'CraftShopper'
    end

    if core() then
      core().Set('listName', value)
    end

    self:SetText(value)
    self:ClearFocus()
  end

  box:SetScript('OnEnterPressed', commit)
  box:SetScript('OnEditFocusLost', commit)
  box:SetScript('OnEscapePressed', function(self)
    self:SetText(core() and core().Get('listName') or '')
    self:ClearFocus()
  end)

  box:SetScript('OnShow', function(self)
    self:SetText(core() and core().Get('listName') or '')
  end)

  return box, y - 52
end

function options.Build()
  if panel then
    return panel
  end

  panel = CreateFrame('Frame')
  panel.name = L.OPTIONS_TITLE

  local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  title:SetPoint('TOPLEFT', 16, -16)
  title:SetText(L.OPTIONS_TITLE)

  local y = -48

  _, y = listNameBox(panel, y)
  _, y = checkbox(panel, L.OPTIONS_SUBTRACT, y, 'subtractInventory')
  _, y = checkbox(panel, L.OPTIONS_INCLUDE_BANK, y, 'includeBank')
  _, y = checkbox(panel, L.OPTIONS_MULTIPLIER, y, 'useCraftCount')
  _, y = checkbox(panel, L.OPTIONS_REPLACE, y, 'replaceList')
  _, y = checkbox(panel, L.OPTIONS_ANNOUNCE, y, 'announce')
  _, y = checkbox(panel, L.OPTIONS_SHOW_BUTTON, y, 'showButton')

  local reset = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  reset:SetPoint('TOPLEFT', 18, y - 8)
  reset:SetSize(200, 22)
  reset:SetText(L.OPTIONS_RESET_POSITION)
  reset:SetScript('OnClick', function()
    if core() then
      core().Set('point', nil)
    end
    if ns.ui then
      ns.ui.ResetPosition()
    end
  end)

  -- Registration is guarded rather than assumed: if the Settings API is not
  -- there, or rejects the panel, /cshop still works and the addon is not
  -- brought down by a settings page nobody has opened yet.
  if _G.Settings and _G.Settings.RegisterCanvasLayoutCategory then
    local ok, registered = pcall(_G.Settings.RegisterCanvasLayoutCategory, panel, L.OPTIONS_TITLE)
    if ok and registered then
      category = registered
      category.ID = L.OPTIONS_TITLE
      pcall(_G.Settings.RegisterAddOnCategory, category)
    end
  end

  return panel
end

function options.Open()
  options.Build()

  if category and _G.Settings and _G.Settings.OpenToCategory then
    local id = category.GetID and category:GetID() or category.ID
    if pcall(_G.Settings.OpenToCategory, id) then
      return
    end
  end

  -- No Settings API, or it refused the panel. The slash commands cover every
  -- setting the panel does, so listing them is a real answer rather than a
  -- shrug.
  if core() and core().Help then
    core().Help()
  end
end
