-- Zyrumi's Libram: paladin class quest data (generated, do not edit by hand)
-- Quest IDs, names, levels, order and quest givers for World of Warcraft: Forever,
-- from Wowhead's Forever database (quest pages, 2026-11-20), QuestieDB 1.1.3 (Forever) where
-- Wowhead names no quest giver.
-- A step lists one or more quest IDs; any one of them counts (different
-- trainers or branches). zone is an area ID; x, y are map coordinates.

local ADDON_NAME, root = ...

root.QUEST_DATA = {
    {
        key = "start", title = "First lessons", reward = "Meet your paladin trainer", faction = "Alliance", level = 1,
        steps = {
            { ids = { 3101, 3107 }, name = "Consecrated Letter", level = 1, giver = "Marshal McBride", zone = 12, x = 48.8, y = 41.6 },
        },
    },
    {
        key = "redemption", title = "Redemption", reward = "Learn Redemption", faction = "Alliance", level = 12,
        races = 1,
        spell = 7328,
        steps = {
            { ids = { 2998, 3681 }, name = "Tome of Divinity", level = 12, giver = "Brother Wilhelm", zone = 12, x = 41.0, y = 66.0 },
            { ids = { 1641 }, name = "The Tome of Divinity", level = 12, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1642 }, name = "The Tome of Divinity", level = 12, giver = "Tome of Divinity" },
            { ids = { 1643 }, name = "The Tome of Divinity", level = 12, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1644 }, name = "The Tome of Divinity", level = 12, giver = "Stephanie Turner", zone = 1519, x = 63.6, y = 72.2 },
            { ids = { 1780 }, name = "The Tome of Divinity", level = 12, giver = "Stephanie Turner", zone = 1519, x = 63.6, y = 72.2 },
            { ids = { 1781 }, name = "The Tome of Divinity", level = 12, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1786 }, name = "The Tome of Divinity", level = 12, giver = "Gazin Tenorm", zone = 1519, x = 49.6, y = 45.0 },
            { ids = { 1787, 1790 }, name = "The Tome of Divinity", level = 12, giver = "Henze Faulk", zone = 12, x = 72.6, y = 51.4 },
            { ids = { 1788 }, name = "The Tome of Divinity", level = 12, giver = "Gazin Tenorm", zone = 1519, x = 49.6, y = 45.0 },
        },
    },
    {
        key = "redemption", title = "Redemption", reward = "Learn Redemption", faction = "Alliance", level = 12,
        races = 4,
        spell = 7328,
        steps = {
            { ids = { 2997, 2999, 3000 }, name = "Tome of Divinity", level = 12, giver = "Azar Stronghammer", zone = 1, x = 47.6, y = 52.0 },
            { ids = { 1645 }, name = "The Tome of Divinity", level = 12, giver = "Tiza Battleforge", zone = 1537, x = 27.4, y = 12.0 },
            { ids = { 1646 }, name = "The Tome of Divinity", level = 12, giver = "Tome of Divinity" },
            { ids = { 1647 }, name = "The Tome of Divinity", level = 12, giver = "Tiza Battleforge", zone = 1537, x = 27.4, y = 12.0 },
            { ids = { 1648 }, name = "The Tome of Divinity", level = 12, giver = "John Turner", zone = 1537, x = 27.8, y = 70.0 },
            { ids = { 1778 }, name = "The Tome of Divinity", level = 12, giver = "John Turner", zone = 1537, x = 27.8, y = 70.0 },
            { ids = { 1779 }, name = "The Tome of Divinity", level = 12, giver = "Tiza Battleforge", zone = 1537, x = 27.4, y = 12.0 },
            { ids = { 1783 }, name = "The Tome of Divinity", level = 12, giver = "Muiredon Battleforge", zone = 1537, x = 23.6, y = 8.8 },
            { ids = { 1784, 1789 }, name = "The Tome of Divinity", level = 12, giver = "Narm Faulk", zone = 1, x = 78.2, y = 58.0 },
            { ids = { 1785 }, name = "The Tome of Divinity", level = 12, giver = "Muiredon Battleforge", zone = 1537, x = 23.6, y = 8.8 },
        },
    },
    {
        key = "verigan", title = "Verigan's Fist", reward = "Verigan's Fist (two-handed mace)", faction = "Alliance", level = 20,
        items = { 6953 },
        steps = {
            { ids = { 1793, 1794 }, name = "The Tome of Valor", level = 20, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1649 }, name = "The Tome of Valor", level = 20, giver = "Tome of Valor" },
            { ids = { 1650 }, name = "The Tome of Valor", level = 20, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1651 }, name = "The Tome of Valor", level = 20, giver = "Daphne Stilwell", zone = 40, x = 42.3, y = 88.5 },
            { ids = { 1652 }, name = "The Tome of Valor", level = 20, giver = "Daphne Stilwell", zone = 40, x = 42.3, y = 88.5 },
            { ids = { 1653 }, name = "The Test of Righteousness", level = 20, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 1654 }, name = "The Test of Righteousness", level = 20, giver = "Jordan Stilwell", zone = 1, x = 52.4, y = 36.8 },
            { ids = { 1806 }, name = "The Test of Righteousness", level = 20, giver = "Jordan Stilwell", zone = 1, x = 52.4, y = 36.8 },
        },
        side = {
            { ids = { 1442 }, name = "Seeking the Kor Gem", level = 20, giver = "Thundris Windweaver", zone = 148, x = 37.4, y = 40.2 },
            { ids = { 1655 }, name = "Bailor's Ore Shipment", level = 20, giver = "Bailor Stonehand", zone = 38, x = 36.0, y = 45.0 },
        },
    },
    {
        key = "divinestorm", title = "Cloak of the Divine Storm", reward = "Cloak of the Divine Storm", faction = "Alliance", level = 22,
        items = { 277205 },
        steps = {
            { ids = { 78088 }, name = "A Strange Artifact", level = 22, giver = "Strange Orb", zone = 148, x = 56.2, y = 26.4 },
            { ids = { 78089 }, name = "Advice From Stormwind", level = 22, giver = "Delgren the Purifier", zone = 331, x = 26.2, y = 38.6 },
            { ids = { 78090 }, name = "A Second Opinion", level = 22, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 78091 }, name = "Earning Your Salt", level = 22, giver = "Ursula Deline", zone = 1519, x = 40.0, y = 84.2 },
            { ids = { 78092 }, name = "It Must Be Destroyed", level = 22, giver = "Ursula Deline", zone = 1519, x = 40.0, y = 84.2 },
            { ids = { 78093 }, name = "Return to Delgren", level = 22, giver = "Shattered Orb", zone = 331, x = 89.4, y = 77.1 },
        },
    },
    {
        key = "vindication", title = "Pauldrons of Vindication", reward = "Pauldrons of Vindication", faction = "Alliance", level = 35,
        items = { 277236 },
        steps = {
            { ids = { 96438 }, name = "Battle at the Mannoroc Coven", level = 35, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 79939 }, name = "The Broken Hammer", level = 35, giver = "Broken Warhammer", zone = 405, x = 52.7, y = 84.8 },
            { ids = { 79940 }, name = "A Lost Brother", level = 35, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 79945 }, name = "Orders from the Grand Crusader", level = 35 },
            { ids = { 79946 }, name = "A Brother In Need", level = 35, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 96449 }, name = "Aeonas's Secret Refuge", level = 35, giver = "Harold Riggs", zone = 11, x = 8.0, y = 58.4 },
            { ids = { 79963 }, name = "By The Light's Grace", level = 35, giver = "Aeonas", zone = 796 },
            { ids = { 79970 }, name = "Aeonas the Vindicated", level = 35, giver = "Aeonas", zone = 796 },
        },
    },
    {
        key = "warhorse", title = "Warhorse", reward = "Summon Warhorse", faction = "Alliance", level = 40,
        spell = { 13819, 1279399 },
        steps = {
            { ids = { 1661, 4485, 4486 }, name = "The Tome of Nobility", level = 40, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
        },
    },
    {
        key = "whisper", title = "Whisper of Aeonas", reward = "Whisper", faction = "Alliance", level = 44,
        items = { 221518 },
        steps = {
            { ids = { 81762 }, name = "Some Good News", level = 45, giver = "Aeonas the Vindicated", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 81764 }, name = "The Mysterious Merchant", level = 45, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 81765 }, name = "Elrick, Paladin of the Silver Hand", level = 45, giver = "Elrick", zone = 15, x = 66.4, y = 45.4 },
            { ids = { 81766 }, name = "The Bloody Missive", level = 45 },
            { ids = { 96476 }, name = "In Search of Aeonas", level = 45, giver = "Katherine the Pure", zone = 1519, x = 48.6, y = 49.2 },
            { ids = { 81790 }, name = "Materials of Significance", level = 45, giver = "Gregory", zone = 361, x = 44.6, y = 52.0 },
            { ids = { 81885 }, name = "The Ritual", level = 45, giver = "Aeonas the Vindicated", zone = 361, x = 45.0, y = 52.0 },
            { ids = { 82135 }, name = "The Price of Hope", level = 44, giver = "Aeonas the Vindicated", zone = 361, x = 45.0, y = 52.0 },
        },
        side = {
            { ids = { 81944 }, name = "A Newly Discovered Purpose...", level = 45, giver = "Brave Stonetorch", zone = 267, x = 67.4, y = 14.8 },
        },
    },
    {
        key = "mightstone", title = "The Mightstone", reward = "Mightstone weapon", faction = "Alliance", level = 50,
        items = { 20504, 20505, 20512 },
        choice = true,
        steps = {
            { ids = { 8415 }, name = "Chillwind Point", level = 50, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 8414 }, name = "Dispelling Evil", level = 50, giver = "Commander Ashlam Valorfist", zone = 28, x = 42.8, y = 84.0 },
            { ids = { 8416 }, name = "Inert Scourgestones", level = 50, giver = "High Priest Thel'danis", zone = 28, x = 52.0, y = 82.8 },
            { ids = { 8418 }, name = "Forging the Mightstone", level = 50, giver = "Commander Ashlam Valorfist", zone = 28, x = 42.8, y = 84.0 },
        },
    },
    {
        key = "thane", title = "Hammer of the Fallen Thane", reward = "Hammer of the Fallen Thane", faction = "Alliance", level = 54,
        items = { 227935 },
        steps = {
            { ids = { 84318 }, name = "Oi!", level = 54, giver = "Orthas", zone = 139, x = 61.2, y = 69.2 },
            { ids = { 84319 }, name = "Oh No Ye Don't!", level = 54, giver = "Orthas", zone = 139, x = 61.2, y = 69.2 },
            { ids = { 84330 }, name = "A Wee Bit O' Necromancy", level = 54, giver = "Orthas", zone = 139, x = 61.2, y = 69.2 },
            { ids = { 84414 }, name = "Send Me On Me Way", level = 54, giver = "Rotting Dwarf Corpse", zone = 139, x = 27.4, y = 85.8 },
            { ids = { 84332 }, name = "A Thane's Gratitude", level = 54, giver = "Mysterious Chest", zone = 139, x = 27.4, y = 85.8 },
        },
    },
    {
        key = "charger", title = "Charger", reward = "Summon Charger", faction = "Alliance", level = 60,
        spell = { 23214 },
        steps = {
            { ids = { 7638, 7670 }, name = "Lord Grayson Shadowbreaker", level = 60, giver = "Duthorian Rall", zone = 1519, x = 50.6, y = 47.4 },
            { ids = { 7637 }, name = "Emphasis on Sacrifice", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 7639 }, name = "To Show Due Judgment", level = 60, giver = "High Priest Rohan", zone = 1537, x = 25.0, y = 8.4 },
            { ids = { 7640 }, name = "Exorcising Terrordale", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 7641 }, name = "The Work of Grimand Elmore", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 7642 }, name = "Collection of Goods", level = 60, giver = "Grimand Elmore", zone = 1519, x = 59.6, y = 34.0 },
            { ids = { 7643 }, name = "Ancient Equine Spirit", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 7644 }, name = "Blessed Arcanite Barding", level = 60, giver = "Ancient Equine Spirit", zone = 2557 },
            { ids = { 7646 }, name = "The Divination Scryer", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
            { ids = { 7647 }, name = "Judgment and Redemption", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
        },
        side = {
            { ids = { 7645 }, name = "Manna-Enriched Horse Feed", level = 60, giver = "Merideth Carlson", zone = 267, x = 52.0, y = 55.6 },
            { ids = { 7648 }, name = "Grimand's Finest Work", level = 60, giver = "Grimand Elmore", zone = 1519, x = 59.6, y = 34.0 },
            { ids = { 7666 }, name = "Again Into the Great Ossuary", level = 60, giver = "Lord Grayson Shadowbreaker", zone = 1519, x = 48.6, y = 50.0 },
        },
    },
    {
        key = "start", title = "Bandarion Keep", reward = "Your first paladin lessons", faction = "Horde", level = 1,
        steps = {
            { ids = { 98601 }, name = "A Difficult Path", level = 1, giver = "Shadow Priest Sarvis", zone = 85, x = 30.8, y = 66.2 },
            { ids = { 90902 }, name = "Rediscovering the Light", level = 2, giver = "Aramis Hammerhand", zone = 85, x = 31.0, y = 66.2 },
            { ids = { 91208 }, name = "Coming to Terms", level = 4, giver = "Aramis Hammerhand", zone = 85, x = 31.0, y = 66.2 },
            { ids = { 91209 }, name = "Continue Your Training", level = 4, giver = "Aramis Hammerhand", zone = 85, x = 31.0, y = 66.2 },
            { ids = { 91282 }, name = "A Second Home", level = 8, giver = "Shari Stilwell", zone = 85, x = 60.2, y = 52.6 },
            { ids = { 91285 }, name = "Murlocs at the Gates", level = 7, giver = "Breton Samuels", zone = 85, x = 21.8, y = 45.2 },
            { ids = { 91294 }, name = "Touring the Grounds", level = 8, giver = "Breton Samuels", zone = 85, x = 21.8, y = 45.2 },
            { ids = { 91316 }, name = "Making Repairs", level = 8, giver = "Jorin Croge", zone = 85, x = 22.6, y = 44.8 },
            { ids = { 91317 }, name = "The Tarnished", level = 9, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 95803 }, name = "A Token of Good Faith", level = 9, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
        },
    },
    {
        key = "redemption", title = "Redemption", reward = "Learn Redemption", faction = "Horde", level = 12,
        spell = 7328,
        steps = {
            { ids = { 94427 }, name = "A Lesson in Divinity", level = 12, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 94434 }, name = "A Lesson in Divinity", level = 12, giver = "Tanis Alderwood", zone = 1497, x = 65.6, y = 37.8 },
            { ids = { 94435 }, name = "A Lesson in Divinity", level = 12, giver = "Tanis Alderwood", zone = 1497, x = 65.6, y = 37.8 },
            { ids = { 94436 }, name = "A Lesson in Divinity", level = 12, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 94438 }, name = "A Lesson in Divinity", level = 12, giver = "Deathguard Billmuth", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 94440 }, name = "A Lesson in Divinity", level = 12, giver = "Deathguard Falgan", zone = 85, x = 86.6, y = 47.6 },
            { ids = { 94441 }, name = "A Lesson in Divinity", level = 12, giver = "Deathguard Billmuth", zone = 85, x = 22.0, y = 44.6 },
        },
    },
    {
        key = "moonsilver", title = "Moonsilver Blade and Wolfsbane", reward = "Moonsilver Blade, then Wolfsbane", faction = "Horde", level = 18,
        items = { 268484, 267369 },
        steps = {
            { ids = { 91858 }, name = "Diplomatic Incident", level = 18, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 91859 }, name = "A Curious Pair", level = 18, giver = "Trevan Rol", zone = 130, x = 43.4, y = 41.0 },
            { ids = { 91860 }, name = "A Grim Fate", level = 18, giver = "Deathguard Baldren", zone = 130, x = 45.6, y = 41.8 },
            { ids = { 91861 }, name = "Into Fenris Keep", level = 18, giver = "Charred Remains", zone = 130, x = 65.0, y = 34.2 },
            { ids = { 91862 }, name = "Lumina Windsinger", level = 18, giver = "Lumina Windsinger", zone = 130, x = 65.7, y = 27.4 },
            { ids = { 96204 }, name = "The Windshaper's Wrath", level = 18, giver = "Lumina Windsinger", zone = 130, x = 65.7, y = 27.4 },
            { ids = { 95034 }, name = "The Debt", level = 18, giver = "Lumina Windsinger", zone = 130, x = 43.2, y = 41.0 },
            { ids = { 95036 }, name = "A Moon-Kissed Blade", level = 20, giver = "Lumina Windsinger", zone = 130, x = 43.2, y = 41.0 },
            { ids = { 95111 }, name = "An Underrated Talent", level = 20, giver = "Trevan Rol", zone = 130, x = 43.4, y = 41.0 },
            { ids = { 95125 }, name = "Ott's Masterwork", level = 20, giver = "Ott", zone = 267, x = 60.4, y = 26.0 },
            { ids = { 95126 }, name = "The Moonsilver Blade", level = 20, giver = "Ott", zone = 267, x = 60.4, y = 26.0 },
            { ids = { 95140 }, name = "Old Fire-Eye", level = 20, giver = "Lumina Windsinger", zone = 130, x = 43.2, y = 41.0 },
        },
        side = {
            { ids = { 95042 }, name = "Seeking the Kor Gem", level = 20, giver = "Ulric Frostveil", zone = 331, x = 11.8, y = 34.4 },
        },
    },
    {
        key = "warhorse", title = "Warhorse", reward = "Summon Warhorse", faction = "Horde", level = 40,
        spell = { 13819, 1279399 },
        steps = {
            { ids = { 97022 }, name = "Report to Danitha", level = 40, giver = "Alodan the Hopeful", zone = 1497, x = 47.6, y = 14.8 },
            { ids = { 94971 }, name = "A Paladin's Steed", level = 40, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
        },
    },
    {
        key = "mourning", title = "Sword of Mourning", reward = "Sword of Mourning", faction = "Horde", level = 50,
        items = { 286408 },
        steps = {
            { ids = { 93030 }, name = "The Knight of Mourning", level = 50, giver = "Knight of Mourning", zone = 85, x = 17.6, y = 67.4 },
            { ids = { 99187 }, name = "The Reliquary of Tyr", level = 50, giver = "Knight of Mourning", zone = 85, x = 17.6, y = 67.4 },
        },
    },
    {
        key = "charger", title = "Charger", reward = "Forsaken Charger", faction = "Horde", level = 60,
        spell = { 1296534 },
        steps = {
            { ids = { 97174 }, name = "A Worthy Endeavor", level = 60, giver = "Alodan the Hopeful", zone = 85, x = 21.8, y = 45.2 },
            { ids = { 97175 }, name = "Due Sacrifice", level = 60, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 97177 }, name = "Acts of Mercy", level = 60, giver = "Zayus", zone = 1637, x = 35.6, y = 87.2 },
            { ids = { 97176 }, name = "Exorcising Terrordale", level = 60, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 97182 }, name = "An Offering of Vengeance", level = 60 },
            { ids = { 97178 }, name = "Ott of Tarren Mill", level = 60, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 97179 }, name = "Collection of Goods", level = 60, giver = "Ott", zone = 267, x = 60.4, y = 26.0 },
            { ids = { 97183 }, name = "Blessed Arcanite Barding", level = 60 },
            { ids = { 97184 }, name = "The Divination Scryer", level = 60, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
            { ids = { 97185 }, name = "Justice and Retribution", level = 60, giver = "Danitha Morr", zone = 85, x = 22.0, y = 44.6 },
        },
        side = {
            { ids = { 97186 }, name = "Manna-Enriched Horse Feed", level = 60, giver = "Nathanos Blightcaller", zone = 139, x = 26.6, y = 74.8 },
            { ids = { 97180 }, name = "Ott's Finest Work", level = 60, giver = "Ott", zone = 267, x = 60.4, y = 26.0 },
        },
    },
}
