# CraftShopper

A World of Warcraft Retail addon that puts the reagents of the recipe you are
looking at onto an [Auctionator](https://www.curseforge.com/wow/addons/auctionator)
shopping list — so you can walk to the auction house and buy them in one go.

Open a profession, pick a recipe, click **To shopping list**. The reagents you
are short of land on an Auctionator shopping list called `CraftShopper`, with
the right quantities next to them.

## What it does

- **Reads the open recipe** from the Retail profession window — the crafting
  page, a crafting-order view, or the customer-order form.
- **Only basic reagents.** Optional, finishing and modifying reagents are
  choices you make per craft, not things a recipe needs, so they are left out.
- **Subtracts what you already own** — bags, and by default the bank, reagent
  bank and warband bank too. Only the shortfall goes on the list.
- **Multiplies by the craft count** you dialled up in the profession window, so
  20× a recipe puts 20× the reagents on the list.
- **Adds to the list rather than replacing it.** Click through five recipes and
  you get one list with the totals. Rows you put there yourself are left exactly
  as they were.

## Installing

CraftShopper needs Auctionator. Without it there is nothing to write to, and the
addon says so instead of failing quietly.

Download a release and drop the `CraftShopper` folder into
`World of Warcraft/_retail_/Interface/AddOns/`. A plain clone of this repository
works too — the folder inside it is already named correctly.

## Using it

The button sits just outside the top-right corner of the profession window.
Shift-drag moves it; `/cshop reset` puts it back.

| Command | |
| --- | --- |
| `/cshop` or `/cshop add` | send the open recipe to the shopping list |
| `/cshop add 20` | …as if you were crafting it 20 times |
| `/cshop list <name>` | write to a differently named shopping list |
| `/cshop own` | toggle subtracting what you already own |
| `/cshop bank` | toggle counting the bank and reagent bank |
| `/cshop replace` | toggle replacing the list instead of adding to it |
| `/cshop button` | toggle the button in the profession window |
| `/cshop reset` | put the button back where it started |
| `/cshop diag` | report what the client and Auctionator are answering to |

Settings are also in the interface options, under **CraftShopper**.

`/cshop diag` is the first thing to run when something looks wrong. It prints
which Blizzard and Auctionator APIs it found, whether a recipe is open, and what
craft count it read. Run it with a profession window open — most of what it
checks only exists once `Blizzard_Professions` has loaded.

## Decisions worth knowing about

**Crafting quality is not passed through.** A reagent that comes in quality
tiers goes on the list under its plain name, with no tier filter, so Auctionator
shows every tier and you buy whichever is cheapest. Every tier you already own
still counts towards what you have. If you specifically want tier 3 of
something, set that on the row in Auctionator — CraftShopper will not overwrite
it, because quality is part of how it matches rows.

**Sub-recipes are not resolved.** A reagent you could craft yourself goes on the
list as the finished reagent, not as its own ingredients. Resolving recursively
means guessing whether you would rather buy or craft each step, and guessing
wrong is expensive.

**Quantities are summed, including into rows with no quantity.** An Auctionator
row with a blank quantity means "any"; adding 20 to it produces 20. The
alternative would be for the count you just asked for to silently not appear.

**The button floats outside the window** rather than sitting inside Blizzard's
layout. The inside of the profession window is rearranged nearly every expansion
and has no free space that stays free — a button placed in it would sooner or
later overlap something, or stop existing. Outside, the worst case is that it is
in a place you do not like, which you can fix by dragging it.

## Building on it

```sh
lua5.4 tests/reagents_spec.lua
lua5.4 tests/list_spec.lua
luacheck .
```

`Reagents.lua` (what a craft needs, minus what you own) and `List.lua` (merging
into a list somebody else's rows are on) hold all the logic and touch no frames,
which is why they can be tested outside the game. Everything else needs a
client. See `CLAUDE.md` for the rules that keep it that way.

## Licence

MIT.
