# Zyrumi's Libram

A paladin helper for World of Warcraft: Forever. It works the moment you log in: no setup, no assignment grid, nothing on screen until something needs you.

## What it does

**Buff reminders with one-key buffing**
- An icon appears when your aura, your own blessing or a group member's blessing is missing or about to run out. Click it to cast.
- Bind **Cast the next buff** (Options > Keybindings > AddOns) and press it until the icons are gone.
- Each group member gets the blessing that suits their class and group role: Might for warriors and rogues, Wisdom for casters and healers, Kings for tanks and hunters. Might is melee only on Forever, so hunters never get it.
- If another paladin already gave someone that blessing, they get their next best.
- At a campfire, camp items that can't stack with a blessing count as that blessing: Fish Bowl for Kings, Mana Well for Wisdom, Lodestone for Might.
- Right-click a blessing icon to choose another blessing for that person. Choose per class on the settings page.
- Greater blessings in raids (or any group) when you carry Symbols of Kings, one cast per class.
- Optional Symbol of Kings restock at vendors, never more than you can pay for.
- Righteous Fury reminder, only while you tank.

**Tank / DPS buttons**
- Two buttons above your action bar. Tank puts on your "Tank" gear set, turns the action bar to your tank page and casts Righteous Fury. DPS does the opposite. The Tank button toggles, so one key switches back and forth.
- The bar swap works in combat; gear catches up when you click again after the fight.

**Threat for tanks**
- An icon above each enemy nameplate and your target: yours, slipping, or on someone else (with their name).

**Healer mana after combat**
- When a fight ends and you are tanking, a warning if a healer is under 20% mana.

**Cleanse buttons**
- A small button beside your own and each party member's frame. Click it to Cleanse that person, no targeting.

**Class quest checklist**
- Every paladin class quest chain for your faction and race on Forever: Redemption, Verigan's Fist, the new Cloak of the Divine Storm, Pauldrons of Vindication, Whisper, the Mightstone, Hammer of the Fallen Thane, the Warhorse and the Charger for the Alliance; Bandarion Keep, Redemption, the Moonsilver Blade and Wolfsbane, the Warhorse, the Sword of Mourning and the Forsaken Charger for the Horde.
- Shows what is done, the next step, and who gives it and where. Ticks itself off as you finish quests.
- Click a chain to put a map pin (and a TomTom arrow, if you use TomTom) on where its next step starts.
- Each chain shows its reward as the real item or spell; hover it for the game's own tooltip.
- A line in chat when you reach the level for a new one.

## Settings

Esc > Options > AddOns > Zyrumi's Libram, the minimap button, the minimap's addon menu, or `/libram`.

| Command | What it does |
|---|---|
| `/libram` | open the settings |
| `/libram move` | unlock the frames to move them (`/libram lock` to lock) |
| `/libram reset` | put every frame back where it started |
| `/libram status` | what the buff reminders see right now |
| `/libram quests` | your class quest checklist |
| `/libram healers` | why the healer mana warning shows or not |
| `/libram welcome` | show the welcome window again |

## Notes

- Forever hides most buff details from addons during fights. Reminders wait until the fight is over. Nothing is guessed: if the game won't say what someone has, no icon shows.
- Spell names come from the game, so any client language works. The addon's own text is English.
- With PallyPower loaded, raid blessings are left to PallyPower.
