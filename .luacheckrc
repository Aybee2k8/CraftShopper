std = 'lua51'

exclude_files = { '.luarocks' }

-- Unused self-documenting arguments are idiomatic in event handlers.
unused_args = false

-- WoW globals the addon reads.
read_globals = {
  'CreateFrame',
  'GetBuildInfo',
  'GetItemCount',
  'GetItemInfo',
  'GetLocale',
  'UIParent',
  'GameTooltip',
  'IsShiftKeyDown',
  'Settings',
  'C_AddOns',
  'C_Item',
  'C_Timer',
  'C_TradeSkillUI',
  'Enum',
  'Item',
  'Auctionator',
  'ProfessionsFrame',
  'wipe',
  'select',
  'unpack',
}

-- Globals the addon defines.
globals = {
  'CraftShopperDB',
  'CraftShopper_OnAddonCompartmentClick',
  'SLASH_CRAFTSHOPPER1',
  'SLASH_CRAFTSHOPPER2',
  'SlashCmdList',
}

-- The test harness runs on stock Lua 5.4 and stands in for the client itself,
-- so it neither has nor needs the globals above.
files['tests/'] = {
  std = 'lua54',
}
