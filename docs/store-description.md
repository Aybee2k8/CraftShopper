# Addon page descriptions

Copy-and-paste text for CurseForge, Wago, WoWInterface and anywhere else the
addon is listed. Kept in the repository so the description cannot drift away
from what the addon actually does.

Most addon sites accept Markdown or have a rich-text editor that takes pasted
formatting. CurseForge's editor does; if a site wants BBCode instead, the
headings and bullet lists are the only things that need converting.

**Before publishing anywhere, read [Accuracy](#accuracy) at the bottom.**

---

## English

### Summary (short field, one line)

> Sends the reagents you are short of straight from the profession window to an Auctionator shopping list.

### Description

**CraftShopper** turns the recipe you are looking at into a shopping list you
can actually buy from.

You pick a recipe, decide you want twenty of them, and then comes the part
nobody enjoys: working out what twenty costs in reagents, subtracting what is
already in your bags, and typing each name into the auction house by hand.
CraftShopper does that in one click. What you are short of lands on an
Auctionator shopping list, with the right quantities, ready to buy.

#### What it does

- **Reads the recipe you have open** — the crafting page, a crafting-order
  view, or the customer-order form.
- **Buys for as many crafts as you mean to make.** Type the number into the box
  under the button. It sticks across sessions.
- **Subtracts what you already own** — bags, and by default the bank, reagent
  bank and warband bank as well. Only the shortfall is bought.
- **Adds to the list instead of replacing it.** Click through five recipes and
  you get one list with the totals, not five lists.
- **Leaves your own rows alone.** Anything you put on that list yourself comes
  back out exactly as you left it.

Only basic reagents are included. Optional, finishing and modifying reagents are
choices you make per craft, not things the recipe requires, so buying them for
you would be presumptuous.

#### Setting it up

Nothing to configure to get started — open a profession and the button is
there, just outside the top-right corner of the window. Drag it wherever you
like.

Type `/cshop options` for the settings, click **CraftShopper** in the minimap's
addon compartment, or find it under Game Menu → Options → AddOns.

- Name the shopping list it writes to
- Turn off subtracting your stock, if you would rather buy regardless
- Decide whether the bank and reagent bank count as stock
- Replace the list each time instead of adding to it
- Hide the button and use the commands instead

#### Commands

| Command | Effect |
| --- | --- |
| `/cshop` or `/cshop add` | Send the open recipe to the shopping list |
| `/cshop add 20` | …as if you were crafting it twenty times |
| `/cshop count 20` | Buy for twenty crafts from now on |
| `/cshop preview` | Show needs, stock and shortfall without buying anything |
| `/cshop list <name>` | Write to a differently named shopping list |
| `/cshop own` | Toggle subtracting what you already own |
| `/cshop bank` | Toggle counting the bank and reagent bank |
| `/cshop replace` | Toggle replacing the list instead of adding to it |
| `/cshop button` | Toggle the button in the profession window |
| `/cshop reset` | Put the button back where it started |
| `/cshop diag` | Report what your client and Auctionator are answering to |

**Nothing landed on the list?** Usually that means you already own the
reagents — CraftShopper subtracts your stock, so a recipe you have the mats for
adds nothing at all. `/cshop preview` shows the arithmetic: what the recipe
needs, what you are holding, what is left. `/cshop own` turns the subtraction
off.

`/cshop diag` is the one to run when something looks broken. Run it with a
profession window open and a recipe selected, then paste the output into a bug
report — it usually says what went wrong.

#### Notes

- **Auctionator is required.** CraftShopper writes to Auctionator's shopping
  lists; without it there is nothing to write to, and the addon says so rather
  than failing quietly.
- Built for Midnight (12.x) Retail.
- Reagents that come in quality tiers go on the list under their plain name, so
  you see every tier and buy the cheapest. Everything you already own counts,
  whatever its tier.
- Reagents you could craft yourself are bought as the finished reagent. Breaking
  them down further would mean guessing buy-or-craft at every step.
- English and German.
- No libraries, nothing bundled.

---

## Deutsch

### Kurzbeschreibung (einzeiliges Feld)

> Schickt fehlende Zutaten direkt aus dem Berufefenster auf eine Auctionator-Einkaufsliste.

### Beschreibung

**CraftShopper** macht aus dem Rezept, das du gerade ansiehst, eine Einkaufsliste,
mit der du wirklich einkaufen kannst.

Du suchst ein Rezept aus, willst zwanzig davon herstellen — und dann kommt der
Teil, auf den niemand Lust hat: ausrechnen, wie viel Zutaten zwanzig sind,
abziehen, was schon in den Taschen liegt, und jeden Namen von Hand ins
Auktionshaus tippen. CraftShopper erledigt das mit einem Klick. Was dir fehlt,
landet mit der richtigen Menge auf einer Auctionator-Einkaufsliste.

#### Was es macht

- **Liest das geöffnete Rezept** — Herstellungsseite, Handwerksauftrag oder
  Kundenauftragsformular.
- **Kauft für so viele Herstellungen, wie du vorhast.** Zahl in das Feld unter
  dem Knopf eintragen; sie bleibt über Sitzungen erhalten.
- **Zieht deinen Bestand ab** — Taschen und standardmäßig auch Bank,
  Reagenzienbank und Kriegsmeutenbank. Nur die Fehlmenge wird gekauft.
- **Ergänzt die Liste, statt sie zu ersetzen.** Fünf Rezepte hintereinander
  ergeben eine Liste mit Summen, nicht fünf Listen.
- **Lässt deine eigenen Einträge in Ruhe.** Was du selbst auf die Liste gesetzt
  hast, kommt unverändert wieder heraus.

Berücksichtigt werden nur Grundzutaten. Optionale, abschließende und
modifizierende Reagenzien sind Entscheidungen pro Herstellung und keine
Anforderung des Rezepts — sie einfach mitzukaufen wäre anmaßend.

#### Einrichten

Zum Loslegen ist nichts einzustellen: Beruf öffnen, der Knopf sitzt rechts oben
knapp außerhalb des Fensters. Verschieben per Ziehen.

`/cshop options` öffnet die Einstellungen. Alternativ **CraftShopper** im
Addon-Fach an der Minimap anklicken oder unter Spielmenü → Optionen → AddOns
aufrufen.

- Namen der Einkaufsliste festlegen, in die geschrieben wird
- Abziehen des eigenen Bestands ausschalten, wenn du ohnehin kaufen willst
- Festlegen, ob Bank und Reagenzienbank als Bestand zählen
- Liste jedes Mal ersetzen statt ergänzen
- Knopf ausblenden und stattdessen die Befehle nutzen

#### Befehle

| Befehl | Wirkung |
| --- | --- |
| `/cshop` oder `/cshop add` | Offenes Rezept auf die Einkaufsliste setzen |
| `/cshop add 20` | … als würdest du es zwanzigmal herstellen |
| `/cshop count 20` | Ab jetzt für zwanzig Herstellungen einkaufen |
| `/cshop preview` | Bedarf, Bestand und Fehlmenge zeigen, ohne zu kaufen |
| `/cshop list <name>` | In eine anders benannte Einkaufsliste schreiben |
| `/cshop own` | Abziehen des eigenen Bestands umschalten |
| `/cshop bank` | Bank und Reagenzienbank mitzählen umschalten |
| `/cshop replace` | Ersetzen statt Ergänzen umschalten |
| `/cshop button` | Knopf im Berufefenster umschalten |
| `/cshop reset` | Knopf an die ursprüngliche Stelle setzen |
| `/cshop diag` | Ausgeben, worauf Client und Auctionator antworten |

**Es landet nichts auf der Liste?** Meistens heißt das, dass du die Zutaten
bereits hast — CraftShopper zieht deinen Bestand ab, also kommt bei einem Rezept,
für das du alles hast, nichts dazu. `/cshop preview` zeigt die Rechnung: was das
Rezept braucht, was du hast, was fehlt. `/cshop own` schaltet das Abziehen aus.

`/cshop diag` ist der Befehl für den Fehlerfall. Mit geöffnetem Berufefenster und
ausgewähltem Rezept ausführen und die Ausgabe in einen Bugreport kopieren — dort
steht meist direkt, was schiefgelaufen ist.

#### Hinweise

- **Auctionator wird benötigt.** CraftShopper schreibt in dessen Einkaufslisten;
  ohne das Addon gibt es nichts, wohin geschrieben werden könnte — und es sagt
  das, statt stillschweigend nichts zu tun.
- Für Midnight (12.x), Retail.
- Zutaten mit Qualitätsstufen stehen ohne Stufenfilter auf der Liste, du siehst
  also alle Stufen und kaufst die günstigste. Was du besitzt, zählt unabhängig
  von der Stufe.
- Zutaten, die du selbst herstellen könntest, werden als Fertigteil gekauft. Sie
  weiter zu zerlegen hieße, bei jedem Schritt zu raten, ob du kaufen oder
  herstellen willst.
- Deutsch und Englisch.
- Keine Bibliotheken, nichts mitgeliefert.

---

## Footer (goes last on the page, after both languages)

CurseForge requires anything pointing off-platform — source links, issue
trackers, personal sites — to sit at the *bottom* of the description, below the
functional content. This is the only block that links out, so keep it last.

> Open source under the MIT licence. Bug reports and feature requests are
> welcome on the issue tracker.
>
> Quelloffen unter der MIT-Lizenz. Fehlerberichte und Feature-Wünsche sind im
> Issue-Tracker willkommen.

---

## Accuracy

Everything above describes behaviour the addon implements. Most of the central
claims are backed by observation on a live client; one is not, and is flagged
below.

**Confirmed on 12.1.0 (interface 120100), German client, with Auctionator
installed:**

- Reading the open recipe works — the addon named the recipe back.
- **Writing to the Auctionator shopping list works.** Missing reagents appear on
  it. This is the claim the whole description rests on, and it has been seen.
- All four `Auctionator.API.v1` functions the addon uses are present.
- Stock subtraction works — including the case where it correctly adds nothing
  because the player already had everything.

**Not yet confirmed, and the only soft spot in the text above:**

- **The craft-count box.** It was added after the live session that produced
  everything else, so nobody has yet typed 20 into it and checked that twenty
  crafts' worth appears on the list. The logic behind it has its own tests, but
  tests are not a client.
- Whether the button attaches correctly when `Blizzard_Professions` was already
  loaded before CraftShopper — the observed attach came through the other path.

Neither is a reason to soften the text, but **do not publish before clicking
the button once with a count above 1.** If it turned out not to scale, the
description's second bullet would be a straight falsehood, and that is the kind
of thing a first reviewer finds in five minutes.

---

## CurseForge submission checklist

Points from CurseForge's moderation policy that this project actually touches.

**Settled by the text above**

- *English first.* Other languages are allowed, but the English version has to
  appear before them. The order in this file is the order to paste.
- *Summary is one sentence and not copied from the description.* Both are
  written to that rule.
- *Description carries functional information*, not just flavour — what it
  reads, what it writes, the settings and the commands are all listed.
- *Off-platform links sit at the bottom.* That is the Footer block.
- *The name contains no game or class name.* "CraftShopper" is clean.
- *Issue tracker exists.* The repository is public, so a player filing a
  `/cshop diag` paste has somewhere to file it. (This is the one point where
  CraftShopper starts out better off than its neighbour repo did.)

**Needs a decision from you**

- **Set Auctionator as a Required Dependency** in the CurseForge project's
  Relations tab, not just as a sentence in the description. Someone who
  installs CraftShopper alone gets an addon that can only print an error, and a
  one-star review that is entirely fair.

- **Avatar: do not use the in-game spell icon.** The addon uses
  `INV_Misc_Note_06` as its in-game list icon, which is fine — Blizzard's art
  inside Blizzard's client. Uploading that same art as a 400×400 CurseForge
  avatar is a different thing: the policy forbids copyrighted imagery in
  avatars. Draw or generate something original. (400×400, no solid colours,
  avoid WebP — their uploader has a known bug with it.)

- **Every file upload needs a changelog entry.** `CHANGELOG.md` is in the
  repository for this; keep it current and paste the relevant section into the
  file's changelog field on upload. Re-uploads without functional changes are
  explicitly against the Fair Play rule.

**Worth knowing, no action needed**

- *Not a fork, and not framed as one.* CraftShopper reads Auctionator's public
  API and ships none of its code, text or assets. The description says it needs
  Auctionator, which is a dependency, not a lineage. CraftSim does a
  superficially similar job; no code or wording was taken from it either, and
  the description deliberately does not compare itself to anything — implying a
  relationship that does not exist would invite a review over nothing.

- *Tagging.* Profession and auction-house categories both apply. Pick both if
  the form allows it; the addon is useless to someone who has neither interest.
