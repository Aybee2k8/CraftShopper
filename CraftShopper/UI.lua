local _, ns = ...

local L = ns.L
local compat = ns.compat

-- The button in the profession window.
--
-- It is a floating button anchored to the outside of ProfessionsFrame rather
-- than a widget slotted into Blizzard's layout. That is a deliberate trade:
-- the inside of that window is rearranged nearly every expansion and has no
-- free space that stays free, so a button placed in it would either overlap
-- something or stop existing. Anchored outside, it can only ever be in the
-- wrong place -- which the player can fix by dragging it, and which does not
-- hide anything they need.
--
-- It is parented to ProfessionsFrame so it appears and disappears with the
-- window even when it has been dragged somewhere else entirely.

local ui = {}
ns.ui = ui

local DEFAULT_POINT = { 'TOPLEFT', 'ProfessionsFrame', 'TOPRIGHT', 4, -28 }

local button

local function core()
  return ns.core
end

local function applyPosition()
  if not button then
    return
  end

  button:ClearAllPoints()

  local saved = core() and core().Get('point')

  if type(saved) == 'table' and #saved == 4 then
    -- A dragged button is stored against UIParent: the player put it somewhere
    -- on their screen, not somewhere on Blizzard's window, and the two move
    -- independently.
    local ok = pcall(button.SetPoint, button, saved[1], _G.UIParent, saved[2], saved[3], saved[4])
    if ok then
      return
    end
  end

  local anchor = _G[DEFAULT_POINT[2]]
  if anchor then
    pcall(button.SetPoint, button, DEFAULT_POINT[1], anchor, DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
  else
    pcall(button.SetPoint, button, 'CENTER', _G.UIParent, 'CENTER', 0, 0)
  end
end

local function onEnter(self)
  local tooltip = _G.GameTooltip
  if not tooltip then
    return
  end

  tooltip:SetOwner(self, 'ANCHOR_RIGHT')
  tooltip:SetText(L.BUTTON_TOOLTIP_TITLE, 1, 1, 1)

  local listName = core() and core().Get('listName') or ''
  tooltip:AddLine(L.BUTTON_TOOLTIP_LINE:format(listName), nil, nil, nil, true)
  tooltip:AddLine(' ')
  tooltip:AddLine(L.BUTTON_TOOLTIP_DRAG, 0.6, 0.6, 0.6, true)
  tooltip:Show()
end

local function onLeave()
  if _G.GameTooltip then
    _G.GameTooltip:Hide()
  end
end

local function onDragStart(self)
  if not _G.IsShiftKeyDown or not _G.IsShiftKeyDown() then
    return
  end
  self:StartMoving()
end

local function onDragStop(self)
  self:StopMovingOrSizing()

  -- The frame's own anchor after a drag is whatever StartMoving left behind,
  -- relative to its parent -- and the parent is a window the player will move
  -- and close. So the position is converted to UIParent coordinates and stored
  -- as a plain bottom-left offset, which means the same thing next session.
  if not core() then
    return
  end

  local left, bottom = self:GetLeft(), self:GetBottom()
  if not left or not bottom then
    return
  end

  local scale = self:GetEffectiveScale()
  local parentScale = _G.UIParent:GetEffectiveScale()

  if not scale or not parentScale or parentScale == 0 then
    return
  end

  core().Set('point', {
    'BOTTOMLEFT',
    'BOTTOMLEFT',
    math.floor(left * scale / parentScale),
    math.floor(bottom * scale / parentScale),
  })

  applyPosition()
end

local function create(parent)
  local frame = CreateFrame('Button', 'CraftShopperButton', parent, 'UIPanelButtonTemplate')

  frame:SetSize(150, 22)
  frame:SetText(L.BUTTON_LABEL)

  -- The template's font string is the only reliable way to size the button to
  -- its label, and the label is translated, so the width cannot be a constant.
  local fontString = frame.GetFontString and frame:GetFontString()
  if fontString then
    local width = fontString:GetStringWidth()
    if width and width > 0 then
      frame:SetWidth(width + 30)
    end
  end

  frame:SetMovable(true)
  frame:RegisterForDrag('LeftButton')
  frame:SetScript('OnDragStart', onDragStart)
  frame:SetScript('OnDragStop', onDragStop)

  frame:SetScript('OnEnter', onEnter)
  frame:SetScript('OnLeave', onLeave)

  frame:SetScript('OnClick', function()
    if core() then
      core().Send()
    end
  end)

  return frame
end

-- Builds the button and puts it in place. Safe to call more than once: the
-- Professions addon can be loaded before or after us, so both paths call this
-- and whichever gets there first wins.
function ui.Attach()
  local parent = compat.Reach('ProfessionsFrame')
  if not parent then
    return false
  end

  if not button then
    button = create(parent)
  elseif button:GetParent() ~= parent then
    button:SetParent(parent)
  end

  applyPosition()
  ui.Refresh()

  return true
end

function ui.Refresh()
  if not button then
    return
  end

  local show = core() == nil or core().Get('showButton')

  if show then
    button:Show()
  else
    button:Hide()
  end
end

function ui.ResetPosition()
  applyPosition()
end

function ui.Exists()
  return button ~= nil
end
