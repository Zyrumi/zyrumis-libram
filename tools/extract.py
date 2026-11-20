import sys, json; sys.path.insert(0, "tools")
from readdb import *
store = load("x/QuestieDB/QuestieDB_Forever.toc")
ids = dec(store, "X-Quest-IDS", compressed=True)
def s(v): return v.decode("utf-8", "replace") if isinstance(v, bytes) else v
F = {1:"name",2:"start",3:"end",4:"reqLevel",5:"level",6:"races",7:"classes",11:"sourceItem",12:"preGroup",13:"preSingle",14:"children",15:"inGroupWith",16:"exclusiveTo",17:"zoneOrSort",22:"next",24:"special",25:"parent",27:"breadcrumbFor",28:"breadcrumbs",30:"reqSpell",32:"maxLevel",33:"availUntil",34:"availStartingWith",36:"disabledBy"}
out = {}
for qid in ids:
    row = rowdict(dec(store, f"X-Quest-{qid}-S")) or {}
    cls = row.get(7, 0) or 0
    if not (cls & 2) and row.get(17) != -141:
        continue
    q = entity(store, "Quest", qid, [2,3,12,13,14,15,16,28])
    out[qid] = {F[k]: s(v) for k, v in q.items() if k in F}
def place(prefix, i, spawnField, zoneField):
    e = entity(store, prefix, i, [spawnField]) or {}
    sp = e.get(spawnField) or {}
    first = None
    if isinstance(sp, dict):
        for z, pts in sp.items():
            if pts: first = [z, pts[0]]; break
    return {"name": s(e.get(1)), "zone": e.get(zoneField), "spawn": first}
npcs, objs, items = {}, {}, {}
for q in out.values():
    for key in ("start", "end"):
        g = q.get(key) or []
        if isinstance(g, dict):  # sparse: {1: npcs, 2: objects, 3: items}
            g = [g.get(1), g.get(2), g.get(3)]
            q[key] = g
        if len(g) > 0 and g[0]:
            for n in g[0]: npcs[n] = None
        if len(g) > 1 and g[1]:
            for o in g[1]: objs[o] = None
        if len(g) > 2 and g[2]:
            for it in g[2]: items[it] = None
for n in npcs: npcs[n] = place("Npc", n, 7, 9)
for o in objs: objs[o] = place("Object", o, 4, 5)
for it in items:
    e = entity(store, "Item", it, []) or {}
    items[it] = {"name": s(e.get(1))}
json.dump({"quests": out, "npcs": npcs, "objects": objs, "items": items}, open("paladin_quests.json", "w"), indent=1, default=str)
print(len(out), "paladin quests;", len(npcs), "npcs;", len(objs), "objects;", len(items), "items")
