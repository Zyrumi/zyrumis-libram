# CurseForge project text

## Summary (the one line under the name)

Paladin helper for Forever: blessing and aura reminders with one-key buffing, a Tank / DPS switch and a class quest checklist. No setup.

## Description (paste into the description editor, Markdown)

**Zyrumi's Libram** is a paladin helper made for World of Warcraft: Forever. It works the moment you log in: no assignment grid, no setup, and nothing on screen until something needs you.

### Buff reminders with one-key buffing

- An icon appears above your character when your **aura**, **your own blessing** or a **group member's blessing** is missing or about to run out. Click it to cast.
- Bind **Cast the next buff** (Options > Keybindings > AddOns) and press it until the icons are gone. Buffing a whole group is one key.
- Everyone gets the blessing that suits their class and group role: Might for warriors and rogues, Wisdom for casters and healers, Kings for tanks and hunters. Might only adds melee attack power on Forever, so hunters never get it.
- If another paladin already gave someone that blessing, they get their next best one. Your own blessing on someone is never replaced with another.
- Right-click a blessing icon to choose a different blessing for that person, or set one per class on the settings page.
- **Greater Blessings** in raids (or any group, your choice) when you carry Symbols of Kings: one cast covers the whole class.
- Optional **Symbol of Kings restock** at vendors, never more than you can pay for.
- **Righteous Fury** reminder, only while you tank.
- Hidden during fights, while mounted, dead or on a flight path. If the game won't say what someone has, no icon is shown: nothing is guessed.

### Tank / DPS buttons

Two buttons above your action bar. **Tank** puts on your tank gear set, turns your action bar to your tank page and casts Righteous Fury. **DPS** does the opposite. The Tank button toggles, so one key switches you back and forth. The bar swap works in combat; your gear catches up after the fight.

### Class quest checklist

Every paladin class quest chain on Forever for your faction and race, including the new Forsaken paladin chains:

- Alliance: Redemption, Verigan's Fist, Cloak of the Divine Storm, Pauldrons of Vindication, Whisper of Aeonas, the Mightstone, Hammer of the Fallen Thane, the Warhorse and the Charger.
- Horde: Bandarion Keep, Redemption, the Moonsilver Blade and Wolfsbane, the Warhorse, the Sword of Mourning and the Forsaken Charger.

Click the minimap button to see each chain's next step, who gives it and where. Steps tick themselves off as you finish them, and a line in chat tells you when a new class quest opens up at your level.

### Tank and group helpers

- **Threat icons** on enemy nameplates and your target: yours, slipping, or on someone else (with their name).
- **Healer mana warning**: when a fight ends and you are tanking, a warning if a healer is under 20% mana.
- **Cleanse buttons** beside your own and each party member's frame: one click cleanses that person, with a letter showing what kind of debuff they carry.

### Settings and commands

Everything can be switched off, moved and resized. Open the settings with a right-click on the minimap button, from Esc > Options > AddOns > Zyrumi's Libram, or with `/libram`.

- `/libram quests` opens the class quest checklist
- `/libram move` unlocks the frames to move them (`/libram lock` to lock)
- `/libram reset` puts every frame back where it started
- `/libram status` shows what the buff reminders see right now
- `/libram help` lists all commands

### Good to know

- Made for Forever's own spells and quests, not Classic's. Spell names come from the game, so any client language works; the addon's own text is English.
- In raids with PallyPower loaded, group blessings are left to PallyPower.
- Found a bug or have an idea? Open an issue on GitHub: https://github.com/Zyrumi/zyrumis-libram/issues (paste any error text and your addon version).
