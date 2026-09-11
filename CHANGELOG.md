# Changelog

## 0.1.0

First version.

- Button in the profession window that sends the open recipe's reagents to an
  Auctionator shopping list.
- Only basic reagents; optional, finishing and modifying reagents are left out.
- Subtracts bags, bank, reagent bank and warband bank from what goes on the
  list.
- Multiplies by the craft count set in the profession window.
- Adds to the list rather than replacing it, leaving rows the player put there
  untouched.
- Settings panel, slash commands (`/cshop`), and `/cshop diag`.
- `/cshop preview`: need, stock and shortfall for the open recipe, without
  writing to any list.
- German and English.

Measured on a live 12.1.0 client: `Enum.CraftingReagentType.Basic` is 1, not the
widely repeated 0, and `GetAddOnMetadata` cannot read `Interface` — the TOC
carries `X-Interface` for `/cshop diag` to report, with CI asserting the two
agree.
