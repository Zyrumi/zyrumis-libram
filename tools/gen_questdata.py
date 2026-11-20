# Builds ZyrumisLibram/QuestData.lua from QuestieDB (Forever 1.1.3) + Wowhead Forever facts.
# Facts only: quest IDs, names, levels, order, quest givers and where they stand.
import sys, json; sys.path.insert(0, "tools")
from readdb import *
store = load("x/QuestieDB/QuestieDB_Forever.toc")
d = json.load(open("paladin_quests.json"))
Q = {int(k): v for k, v in d["quests"].items()}
NPC = d["npcs"]; OBJ = d["objects"]; ITEM = d["items"]

# Quests QuestieDB lacks: name and level from Wowhead's Forever listing, giver from its quest page.
WOWHEAD = {
    97182: ("An Offering of Vengeance", 60, None), 84332: ("A Thane's Gratitude", 54, "Mysterious Chest"),
    97185: ("Justice and Retribution", 60, "Danitha Morr"), 97176: ("Exorcising Terrordale", 60, "Danitha Morr"),
    82135: ("The Price of Hope", 44, "Aeonas the Vindicated"), 97178: ("Ott of Tarren Mill", 60, None),
    97183: ("Blessed Arcanite Barding", 60, None), 97184: ("The Divination Scryer", 60, None),
    81885: ("The Ritual", 45, None), 84319: ("Oh No Ye Don't!", 54, None), 84414: ("Send Me On Me Way", 54, None),
    97186: ("Manna-Enriched Horse Feed", 60, None), 97180: ("Ott's Finest Work", 60, "Ott"),
}

def extra_entity(prefix, i, spawnField, zoneField):
    e = entity(store, prefix, i, [spawnField]) or {}
    sp = e.get(spawnField) or {}
    first = None
    if isinstance(sp, dict):
        for z, pts in sp.items():
            if pts: first = [z, pts[0]]; break
    nm = e.get(1); nm = nm.decode() if isinstance(nm, bytes) else nm
    return {"name": nm, "zone": e.get(zoneField), "spawn": first}

# Wowhead Forever quest pages (wowhead_check.json, read 2026-11-20) win for quest givers and places.
import os
WH = {}
if os.path.exists("wowhead_check.json"):
    WH = {int(k): v for k, v in json.load(open("wowhead_check.json", encoding="utf-8")).items()}

def info(qid):
    name, lvl, giver = info_questie(qid)
    w = WH.get(qid)
    if w:
        if w.get("title"):
            name = w["title"]
        if w.get("req"):
            lvl = int(w["req"][0])
        st, pt = w.get("start"), w.get("startPt")
        if st:
            giver = {"name": st[2].strip(), "zone": pt and pt["zone"], "spawn": None}
            if pt and pt.get("coord"):
                giver["spawn"] = [pt["zone"], pt["coord"]]
    return name, lvl, giver

def info_questie(qid):
    if qid in Q:
        q = Q[qid]
        name, lvl = q["name"], q.get("reqLevel") or 1
        giver = None
        g = q.get("start") or []
        if isinstance(g, dict): g = [g.get(1), g.get(2), g.get(3)]
        if len(g) > 0 and g[0]:
            giver = NPC.get(str(g[0][0])); kind = "npc"
        elif len(g) > 1 and g[1]:
            giver = OBJ.get(str(g[1][0])); kind = "obj"
        elif len(g) > 2 and g[2]:
            giver = {"name": (ITEM.get(str(g[2][0])) or {}).get("name"), "zone": None, "spawn": None}; kind = "item"
        return name, lvl, giver
    if qid == 93030:
        q = entity(store, "Quest", 93030, [2])
        return "The Knight of Mourning", 50, extra_entity("Npc", q[2][0][0], 7, 9)
    name, lvl, gname = WOWHEAD[qid]
    return name, lvl, ({"name": gname, "zone": None, "spawn": None} if gname else None)

A, H = "Alliance", "Horde"
HU, DW = 1, 4
# (key, title, reward text, faction, races or None, spell(s) that prove it done, steps, side quests)
# Mount spells (Wowhead Forever): Summon Warhorse 13819 and 1279399 (new), Summon Charger 23214,
# Summon Forsaken Charger 1296534.
# A step is an ID, or a tuple of IDs where any one counts (different trainers, branches).
M = [
    ("start", "First lessons", "Meet your paladin trainer", A, None, None,
        [(3101, 3107)], []),
    ("redemption", "Redemption", "Learn Redemption", A, HU, 7328,
        [(2998, 3681), 1641, 1642, 1643, 1644, 1780, 1781, 1786, (1787, 1790), 1788], []),
    ("redemption", "Redemption", "Learn Redemption", A, DW, 7328,
        [(2997, 2999, 3000), 1645, 1646, 1647, 1648, 1778, 1779, 1783, (1784, 1789), 1785], []),
    ("verigan", "Verigan's Fist", "Verigan's Fist (two-handed mace)", A, None, None,
        [(1793, 1794), 1649, 1650, 1651, 1652, 1653, 1654, 1806], [1442, 1655]),
    ("divinestorm", "Cloak of the Divine Storm", "Cloak of the Divine Storm", A, None, None,
        [78088, 78089, 78090, 78091, 78092, 78093], []),
    ("vindication", "Pauldrons of Vindication", "Pauldrons of Vindication", A, None, None,
        [96438, 79939, 79940, 79945, 79946, 96449, 79963, 79970], []),
    ("warhorse", "Warhorse", "Summon Warhorse", A, None, (13819, 1279399),
        [(1661, 4485, 4486)], []),
    ("whisper", "Whisper of Aeonas", "Whisper", A, None, None,
        [81762, 81764, 81765, 81766, 96476, 81790, 81885, 82135], [81944]),
    ("mightstone", "The Mightstone", "Mightstone weapon", A, None, None,
        [8415, 8414, 8416, 8418], []),
    ("thane", "Hammer of the Fallen Thane", "Hammer of the Fallen Thane", A, None, None,
        [84318, 84319, 84330, 84414, 84332], []),
    ("charger", "Charger", "Summon Charger", A, None, (23214,),
        [(7638, 7670), 7637, 7639, 7640, 7641, 7642, 7643, 7644, 7646, 7647], [7645, 7648, 7666]),

    ("start", "Bandarion Keep", "Your first paladin lessons", H, None, None,
        [98601, 90902, 91208, 91209, 91282, 91285, 91294, 91316, 91317, 95803], []),
    ("redemption", "Redemption", "Learn Redemption", H, None, 7328,
        [94427, 94434, 94435, 94436, 94438, 94440, 94441], []),
    ("moonsilver", "Moonsilver Blade and Wolfsbane", "Moonsilver Blade, then Wolfsbane", H, None, None,
        [91858, 91859, 91860, 91861, 91862, 96204, 95034, 95036, 95111, 95125, 95126, 95140], [95042]),
    ("warhorse", "Warhorse", "Summon Warhorse", H, None, (13819, 1279399),
        [97022, 94971], []),
    ("mourning", "Sword of Mourning", "Sword of Mourning", H, None, None,
        [93030, 99187], []),
    ("charger", "Charger", "Forsaken Charger", H, None, (1296534,),
        [97174, 97175, 97177, 97176, 97182, 97178, 97179, 97183, 97184, 97185], [97186, 97180]),
]

def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'

def step_lua(step):
    ids = list(step) if isinstance(step, tuple) else [step]
    name, lvl, giver = info(ids[0])
    parts = ["ids = { " + ", ".join(map(str, ids)) + " }", "name = " + lua_str(name), "level = %d" % lvl]
    if giver and giver.get("name"):
        parts.append("giver = " + lua_str(giver["name"]))
        sp = giver.get("spawn")
        if sp:
            parts.append("zone = %s, x = %.1f, y = %.1f" % (sp[0], sp[1][0], sp[1][1]))
        elif giver.get("zone"):
            parts.append("zone = %s" % giver["zone"])
    return "{ " + ", ".join(parts) + " }"

used = set()
out = ["-- Zyrumi's Libram: paladin class quest data (generated, do not edit by hand)",
       "-- Quest IDs, names, levels, order and quest givers for World of Warcraft: Forever,",
       "-- from Wowhead's Forever database (quest pages, 2026-11-20), QuestieDB 1.1.3 (Forever) where",
       "-- Wowhead names no quest giver.",
       "-- A step lists one or more quest IDs; any one of them counts (different",
       "-- trainers or branches). zone is an area ID; x, y are map coordinates.",
       "", "local ADDON_NAME, root = ...", "", "root.QUEST_DATA = {"]
for key, title, reward, fac, races, spell, steps, side in M:
    lvl = min(info(list(s)[0] if isinstance(s, tuple) else s)[1] for s in steps)
    out.append("    {")
    out.append("        key = %s, title = %s, reward = %s, faction = %s, level = %d,"
               % (lua_str(key), lua_str(title), lua_str(reward), lua_str(fac), lvl))
    if races: out.append("        races = %d," % races)
    if isinstance(spell, tuple): out.append("        spell = { " + ", ".join(map(str, spell)) + " },")
    elif spell: out.append("        spell = %d," % spell)
    out.append("        steps = {")
    for s in steps:
        out.append("            " + step_lua(s) + ",")
        used.update(s if isinstance(s, tuple) else [s])
    out.append("        },")
    if side:
        out.append("        side = {")
        for s in side:
            out.append("            " + step_lua(s) + ",")
            used.add(s)
        out.append("        },")
    out.append("    },")
out.append("}")
open("G:/Claude/ZyrumisLibram/QuestData.lua", "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")

wh = json.load(open("wowhead_ids.json"))
unused_names = {1659, 1660, 1662, 1663, 1664, 3023}
missing = [i for i in wh if i not in used and i not in unused_names]
print("milestones:", len(M), "quests used:", len(used))
print("Wowhead paladin quests not in the checklist:", [(i, info(i)[0]) for i in missing])
