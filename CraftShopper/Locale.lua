local _, ns = ...

-- Strings are kept here rather than inline so the German client -- the one this
-- addon is actually developed against -- reads naturally, without forcing every
-- other locale through a translation that does not exist.
--
-- enUS is the fallback and must stay complete. A locale table only needs the
-- keys it actually translates; anything missing falls through to enUS.

local enUS = {
  BUTTON_LABEL = 'To shopping list',
  BUTTON_TOOLTIP_TITLE = 'CraftShopper',
  BUTTON_TOOLTIP_LINE = 'Adds the reagents of this recipe to the Auctionator shopping list %q.',
  BUTTON_TOOLTIP_DRAG = 'Shift-drag to move the button. /cshop reset puts it back.',

  NO_AUCTIONATOR = 'Auctionator was not found. Install or enable it -- '
    .. 'CraftShopper has nothing to write to without it.',
  NO_RECIPE = 'No recipe is open. Select one in the profession window first.',
  NO_REAGENTS = 'This recipe has no reagents that can be bought at the auction house.',
  NOTHING_MISSING = 'You already have every reagent for %dx %s.',
  NAMES_FAILED = 'The client did not return item names in time. Try again in a moment.',
  WRITE_FAILED = 'Auctionator refused the shopping list: %s',

  ADDED = 'Added %d reagent(s) for %dx %s to the shopping list %q.',
  ADDED_LINE = '  %s x%d',
  REPLACED = 'Replaced the shopping list %q with %d reagent(s) for %dx %s.',

  OPTIONS_TITLE = 'CraftShopper',
  OPTIONS_LIST_NAME = 'Shopping list name',
  OPTIONS_SUBTRACT = 'Subtract what you already own',
  OPTIONS_INCLUDE_BANK = 'Count bank and reagent bank as owned',
  OPTIONS_MULTIPLIER = 'Use the craft count from the profession window',
  OPTIONS_REPLACE = 'Replace the list instead of adding to it',
  OPTIONS_ANNOUNCE = 'Print what was added to chat',
  OPTIONS_SHOW_BUTTON = 'Show the button in the profession window',
  OPTIONS_RESET_POSITION = 'Reset button position',

  SLASH_HELP_HEADER = 'CraftShopper commands:',
  SLASH_HELP = {
    '/cshop add [count] -- send the open recipe to the shopping list',
    '/cshop list <name> -- set the shopping list to write to',
    '/cshop own -- toggle subtracting what you already own',
    '/cshop bank -- toggle counting bank and reagent bank',
    '/cshop replace -- toggle replacing the list instead of adding',
    '/cshop button -- toggle the button in the profession window',
    '/cshop reset -- put the button back where it started',
    '/cshop diag -- report what the client and Auctionator are answering to',
  },

  SETTING_ON = 'on',
  SETTING_OFF = 'off',
  SETTING_CHANGED = '%s: %s',
  LIST_CHANGED = 'Shopping list set to %q.',
  POSITION_RESET = 'Button position reset.',

  DIAG_HEADER = 'CraftShopper diagnostics',
  DIAG_INTERFACE = 'client interface %s, addon declares %s',
  DIAG_OK = '|cff00ff00ok|r',
  DIAG_MISSING = '|cffff4040missing|r',
}

local deDE = {
  BUTTON_LABEL = 'Auf Einkaufsliste',
  BUTTON_TOOLTIP_TITLE = 'CraftShopper',
  BUTTON_TOOLTIP_LINE = 'Setzt die Zutaten dieses Rezepts auf die Auctionator-Einkaufsliste %q.',
  BUTTON_TOOLTIP_DRAG = 'Mit Umschalt ziehen verschiebt den Knopf. /cshop reset setzt ihn zurueck.',

  NO_AUCTIONATOR = 'Auctionator wurde nicht gefunden. Ohne das Addon hat '
    .. 'CraftShopper nichts, wohin es schreiben koennte.',
  NO_RECIPE = 'Es ist kein Rezept geoeffnet. Waehle zuerst eines im Berufefenster aus.',
  NO_REAGENTS = 'Dieses Rezept hat keine Zutaten, die sich im Auktionshaus kaufen lassen.',
  NOTHING_MISSING = 'Du hast bereits alle Zutaten fuer %dx %s.',
  NAMES_FAILED = 'Der Client hat die Gegenstandsnamen nicht rechtzeitig geliefert. '
    .. 'Versuche es gleich noch einmal.',
  WRITE_FAILED = 'Auctionator hat die Einkaufsliste abgelehnt: %s',

  ADDED = '%d Zutat(en) fuer %dx %s zur Einkaufsliste %q hinzugefuegt.',
  ADDED_LINE = '  %s x%d',
  REPLACED = 'Einkaufsliste %q durch %d Zutat(en) fuer %dx %s ersetzt.',

  OPTIONS_TITLE = 'CraftShopper',
  OPTIONS_LIST_NAME = 'Name der Einkaufsliste',
  OPTIONS_SUBTRACT = 'Vorhandenen Bestand abziehen',
  OPTIONS_INCLUDE_BANK = 'Bank und Reagenzienbank mitzaehlen',
  OPTIONS_MULTIPLIER = 'Anzahl aus dem Berufefenster uebernehmen',
  OPTIONS_REPLACE = 'Liste ersetzen statt ergaenzen',
  OPTIONS_ANNOUNCE = 'Hinzugefuegtes im Chat ausgeben',
  OPTIONS_SHOW_BUTTON = 'Knopf im Berufefenster anzeigen',
  OPTIONS_RESET_POSITION = 'Position des Knopfes zuruecksetzen',

  SLASH_HELP_HEADER = 'CraftShopper-Befehle:',
  SLASH_HELP = {
    '/cshop add [anzahl] -- offenes Rezept auf die Einkaufsliste setzen',
    '/cshop list <name> -- Einkaufsliste festlegen, in die geschrieben wird',
    '/cshop own -- Abziehen des eigenen Bestands umschalten',
    '/cshop bank -- Bank und Reagenzienbank mitzaehlen umschalten',
    '/cshop replace -- Ersetzen statt Ergaenzen umschalten',
    '/cshop button -- Knopf im Berufefenster umschalten',
    '/cshop reset -- Knopf an die urspruengliche Stelle setzen',
    '/cshop diag -- ausgeben, worauf Client und Auctionator antworten',
  },

  SETTING_ON = 'an',
  SETTING_OFF = 'aus',
  SETTING_CHANGED = '%s: %s',
  LIST_CHANGED = 'Einkaufsliste auf %q gesetzt.',
  POSITION_RESET = 'Position des Knopfes zurueckgesetzt.',

  DIAG_HEADER = 'CraftShopper-Diagnose',
  DIAG_INTERFACE = 'Client-Interface %s, Addon meldet %s',
  DIAG_OK = '|cff00ff00ok|r',
  DIAG_MISSING = '|cffff4040fehlt|r',
}

local locales = {
  deDE = deDE,
}

local L = setmetatable({}, {
  __index = function(_, key)
    -- A missing key is a bug, but it must never be a Lua error on someone's
    -- screen: returning the key itself keeps the addon usable and makes the
    -- omission obvious in the message.
    return key
  end,
})

for key, value in pairs(enUS) do
  L[key] = value
end

local translated = locales[(_G.GetLocale and _G.GetLocale()) or 'enUS']
if translated then
  for key, value in pairs(translated) do
    L[key] = value
  end
end

ns.L = L
