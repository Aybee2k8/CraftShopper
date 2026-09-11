# CLAUDE.md

Guidance for Claude Code / AI agents working in this repository.

## What this is

A WoW Retail addon for Midnight (12.x), called **CraftShopper**. It reads the
recipe open in the profession window and writes its reagents to an Auctionator
shopping list.

The addon lives in `CraftShopper/`, not at the repository root, so that a clone
or ZIP download already contains a correctly named folder to drop into
`Interface/AddOns`. **The folder name and the `.toc` name must match** — the
client silently skips a folder whose `.toc` does not share its name, and the
addon then never appears in the list at all, not even as out of date. CI asserts
`CraftShopper/CraftShopper.toc` exists for exactly this reason; do not flatten
the layout.

## Before pushing

```sh
lua5.4 tests/reagents_spec.lua
lua5.4 tests/list_spec.lua
luacheck .
for f in CraftShopper/*.lua; do luac5.1 -p "$f"; done
```

All four run in CI. `luacheck` is configured to fail on warnings, so add new WoW
globals to `read_globals` in `.luacheckrc` (or `globals`, if the addon writes to
them) rather than leaving them undeclared.

**The `luac5.1` pass is not redundant.** The client runs Lua 5.1; luacheck and
`lua5.4` both accept syntax 5.1 rejects. The `\z` line continuation is the one
that has already cost a round here: it lints clean, runs clean under 5.4, and is
a syntax error on the client — where Lua errors are hidden by default, so the
addon simply does not load and says nothing about why. Break long strings with
`..`, not `\z`.

## Rules specific to this addon

- **Talk to Auctionator only through `Auctionator.API.v1`.** Its own README says
  that calling anything else is unsupported and may break without warning.
  Reaching into `Auctionator.Shopping.ListManager` would be shorter and is not
  allowed. All of that traffic goes through `Shopping.lua`.

- **Every Auctionator call is wrapped in `pcall`.** The API reports problems by
  raising, not by returning — an unguarded raise from a button click is a Lua
  error on the player's screen.

- **Keep `Reagents.lua` and `List.lua` free of frames and globals.** They are
  the only files the test harness can load, and that is only true while they
  depend on nothing. Logic added elsewhere is logic that cannot be tested.

- **Never touch a Blizzard frame directly.** Everything goes through
  `compat.Reach` / `compat.TryCall` in `Compat.lua`. The Professions UI is
  load-on-demand and its widget names have been renamed more than once; a
  rename must degrade to "no recipe found", never to a Lua error.

- **Adding to a shopping list is a read-merge-write, and the rows are the
  player's.** Auctionator has no append call, so `CreateShoppingList` replaces
  the whole list. A row this addon did not change must come back out byte for
  byte — that is what the `raw` field in `List.Merge` is for, and why
  `tests/list_spec.lua` is as long as it is. Do not "simplify" it into
  re-encoding everything.

- **Fold repeated reagents before subtracting stock, never after.** Two slots of
  one recipe can call for the same item. Subtracting per slot under-buys by
  everything the player owns, once per slot — a quiet wrong answer, which is
  worse than a loud one. There is a test named after this.

- **Route every setting change through `core.Get` / `core.Set`.** The panel, the
  slash commands and the button share them. A value written directly to the
  saved variables from one of them will silently drift from the others.

- **Add new API dependencies to `compat.ProbeOptional`** so `/cshop diag`
  reports them. That command is the first thing to run after a patch, and it
  re-probes on every call because almost nothing it checks exists until
  `Blizzard_Professions` has loaded.

- **Do not introduce named Blizzard templates** beyond the ones already used
  (`UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`).
  Template names and their child layouts churn between expansions, and a missing
  one is a hard error at construction time. Build from primitives and own the
  widget's parts — especially label FontStrings, which the templates expose
  differently across versions.

- **The TOC carries a literal `## Version`, not `@project-version@`.** The
  placeholder is only substituted when a release is built, so a clone install
  would display the placeholder itself. Bump it together with the release tag;
  the release workflow refuses a tag that disagrees with it.

## Deliberate omissions

These were considered and left out. Re-adding one is a decision, not an
oversight — say so in the PR.

- **Crafting quality (`tier`) is not sent to Auctionator.** A tiered reagent
  goes on the list under its plain name so every tier shows and the cheapest
  wins. All tiers still count towards what the player already owns. Quality *is*
  part of `List.Key`, so a row the player tiered themselves is never merged into
  by accident.
- **Sub-recipes are not resolved recursively.** That means deciding, per step,
  whether the player would rather buy or craft — and being wrong is expensive.
- **The button does not disable itself when no recipe is open.** That would mean
  polling the schematic form. Clicking with nothing open prints a line instead.

## What a live client has actually confirmed

Measured on 12.1.0 (interface 120100), German client, with Auctionator
installed, from one `/cshop diag` and one button click on an alchemy recipe:

| | |
| --- | --- |
| All four `Auctionator.API.v1` functions | present |
| `C_TradeSkillUI.GetRecipeSchematic` | present |
| `Enum.CraftingReagentType.Basic` | **1**, not 0 |
| `ProfessionsFrame` | present, and the button attached |
| `CreateMultipleInputBox:GetValue()` | readable, returned 1 |
| `C_Item.GetItemCount` / `GetItemInfo` / `Item` mixin | all present |
| Reading the open recipe end to end | works — it named the recipe back |
| Writing to the Auctionator shopping list | **works** — missing reagents appear on it |

Two corrections that came out of that reading:

1. **`Enum.CraftingReagentType.Basic` is 1.** 0 is widely repeated and is wrong.
   Nothing breaks here only because the value is read by name and passed into
   `Reagents.lua` rather than hardcoded. Do not "simplify" that away.
2. **`GetAddOnMetadata` cannot read `Interface`.** It answers for a fixed set of
   fields plus custom `X-` ones, so `/cshop diag` printed `addon declares ?`.
   The TOC now carries `## X-Interface` alongside `## Interface`, and CI asserts
   they agree.

Still unconfirmed: whether `ProfessionsFrame` exists early enough for
`ui.Attach` on `PLAYER_LOGIN`. The observed attach may have come via
`ADDON_LOADED` instead, which would leave that path dead and unnoticed.

## The first live report was "nothing lands on the list"

Worth keeping, because the addon was working correctly at the time. The click
had hit the "you already have every reagent" path: stock subtraction is on by
default, the player had the reagents, and nothing was added. Compared against
CraftSim — which does not subtract stock — that looks exactly like a broken
addon.

Two changes came out of it, and both are about the same thing. `/cshop preview`
prints the need / have / short arithmetic without writing anything, and the
"nothing was added" message now names the setting that caused it and the command
that shows its working. **"You already have every reagent" is an answer the
player cannot check** — it subtracts a stock count they cannot see from a
requirement they did not state. Any future message that reports a computed
nothing needs the same treatment.

The other report in the same breath: the button moved only with shift held, and
was therefore reported as not movable at all. It is a plain drag now. A modifier
was never needed — `OnDragStart` fires only after the mouse moves while held, so
a click and a drag cannot be confused.

## Branch workflow

One task, one branch off `main`, one topic per PR. Never reuse a merged branch —
after a squash merge the branch diverges and stops being mergeable. Branch fresh
from `main` instead.
