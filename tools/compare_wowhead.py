# Compares ZyrumisLibram/QuestData.lua with Wowhead Forever quest pages (wowhead_check.json).
import json, re

data = open("G:/Claude/ZyrumisLibram/QuestData.lua", encoding="utf-8").read()
wh = {int(k): v for k, v in json.load(open("G:/Claude/_scratch/questiedb/wowhead_check.json", encoding="utf-8")).items()}

# Parse milestones and steps from the generated Lua.
milestones = []
for block in re.split(r"\n    \{\n", data)[1:]:
    head = re.search(r'key = "(\w+)", title = "([^"]+)".*?faction = "(\w+)", level = (\d+)', block, re.S)
    races = re.search(r"races = (\d+)", block)
    steps = []
    for line in block.splitlines():
        m = re.search(r'ids = \{ ([\d, ]+) \}, name = "((?:[^"\\]|\\.)*)", level = (\d+)(.*)', line)
        if not m:
            continue
        rest = m.group(4)
        g = re.search(r'giver = "((?:[^"\\]|\\.)*)"', rest)
        z = re.search(r"zone = (\d+)(?:, x = ([\d.]+), y = ([\d.]+))?", rest)
        steps.append({"ids": [int(i) for i in m.group(1).split(",")], "name": m.group(2).replace('\\"', '"'),
                      "level": int(m.group(3)), "giver": g and g.group(1).replace('\\"', '"'),
                      "zone": z and int(z.group(1)), "x": z and z.group(2) and float(z.group(2)),
                      "y": z and z.group(3) and float(z.group(3)), "side": "side = {" in block[:block.find(line)] })
    milestones.append({"key": head.group(1), "title": head.group(2), "faction": head.group(3),
                       "races": races and int(races.group(1)), "steps": steps})

RACEBIT = {1: 1, 3: 4, 5: 16, 6: 32, 4: 8, 7: 64, 2: 2, 8: 128}
problems = []
def P(m, s, msg):
    problems.append("%s (%s) / %s: %s" % (m["title"], m["faction"], s["ids"], msg))

for m in milestones:
    order = [i for s in m["steps"] if not s["side"] for i in s["ids"]]
    for s in m["steps"]:
        for qid in s["ids"]:
            w = wh.get(qid)
            if not w or w.get("error"):
                P(m, s, "no Wowhead data for %d (%s)" % (qid, w and w.get("error")))
                continue
            if qid == s["ids"][0] and w.get("title") and w["title"] != s["name"]:
                P(m, s, "name: ours %r, Wowhead %r" % (s["name"], w["title"]))
            req = w.get("req") and int(w["req"][0])
            if qid == s["ids"][0] and req and req != s["level"]:
                P(m, s, "required level: ours %d, Wowhead %d" % (s["level"], req))
            side = w.get("side") and w["side"][0].capitalize()
            if side and side in ("Alliance", "Horde") and side != m["faction"]:
                P(m, s, "%d is %s on Wowhead" % (qid, side))
            if m["races"] and w.get("races"):
                if not any(RACEBIT.get(r, 0) & m["races"] for r in w["races"]):
                    P(m, s, "%d races on Wowhead %s, milestone races %d" % (qid, w["races"], m["races"]))
            st = w.get("start")
            if qid == s["ids"][0]:
                if st and s["giver"] and st[2].strip() != s["giver"]:
                    P(m, s, "giver: ours %r, Wowhead %r (%s %s)" % (s["giver"], st[2].strip(), st[0], st[1]))
                if st and not s["giver"]:
                    P(m, s, "giver missing, Wowhead has %r (%s %s)" % (st[2].strip(), st[0], st[1]))
                pt = w.get("startPt")
                if pt and s["zone"] and pt["zone"] != s["zone"]:
                    P(m, s, "zone: ours %s, Wowhead %s %s" % (s["zone"], pt["zone"], pt["zoneName"]))
                if pt and s["x"] is not None and pt.get("coord"):
                    dx, dy = abs(pt["coord"][0] - s["x"]), abs(pt["coord"][1] - s["y"])
                    if dx > 1.5 or dy > 1.5:
                        P(m, s, "place: ours %.1f, %.1f, Wowhead %s in %s" % (s["x"], s["y"], pt["coord"], pt["zoneName"]))
                if pt and not s["x"]:
                    P(m, s, "no coordinates, Wowhead has %s %s" % (pt["zoneName"], pt["coord"]))
            # chain order: Wowhead's series must run in the same order in ours
            for series in w.get("series") or []:
                pos = [order.index(q) for q in series if q in order]
                if pos != sorted(pos):
                    P(m, s, "order differs from Wowhead series %s" % series)
                missing = [q for q in series if q not in order and not any(q in st2["ids"] for st2 in m["steps"])]
                if missing:
                    P(m, s, "Wowhead series has quests not in this chain: %s" % missing)

seen = set()
for p in problems:
    if p not in seen:
        seen.add(p)
        print(p)
print(len(seen), "differences")
