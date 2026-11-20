# Reads QuestieDB's baked TOC store (Forever) without running any of its code.
# Format (from src/read/baked.lua): "## X-<Entity>-<id>-S: base64(CBOR scalar row)",
# "## X-<Entity>-<id>-<field>: base64(CBOR value)", chunked values "~N~" + "-1".."-N",
# "## X-<Entity>-IDS": base64(zlib(CBOR id list)).
import base64, zlib, struct, sys, json, re

def cbor(b, i=0):
    ib = b[i]; mt, ai = ib >> 5, ib & 31; i += 1
    if ai < 24: val = ai
    elif ai == 24: val = b[i]; i += 1
    elif ai == 25: val = struct.unpack(">H", b[i:i+2])[0]; i += 2
    elif ai == 26:
        if mt == 7: return struct.unpack(">f", b[i:i+4])[0], i + 4
        val = struct.unpack(">I", b[i:i+4])[0]; i += 4
    elif ai == 27:
        if mt == 7: return struct.unpack(">d", b[i:i+8])[0], i + 8
        val = struct.unpack(">Q", b[i:i+8])[0]; i += 8
    else: raise ValueError("indefinite length not handled")
    if mt == 0: return val, i
    if mt == 1: return -1 - val, i
    if mt == 2: return b[i:i+val], i + val
    if mt == 3: return b[i:i+val].decode("utf-8"), i + val
    if mt == 4:
        out = []
        for _ in range(val):
            v, i = cbor(b, i); out.append(v)
        return out, i
    if mt == 5:
        out = {}
        for _ in range(val):
            k, i = cbor(b, i); v, i = cbor(b, i); out[k] = v
        return out, i
    if mt == 7:
        return {20: False, 21: True, 22: None}.get(val, val), i
    raise ValueError("type %d" % mt)

def load(path):
    store = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("## X-"):
                k, _, v = line[3:].rstrip("\n").partition(": ")
                store[k] = v
    return store

def stored(store, key):
    v = store.get(key)
    if v is None: return None
    m = re.fullmatch(r"~(\d+)~", v)
    if m: v = "".join(store[key + "-" + str(n)] for n in range(1, int(m.group(1)) + 1))
    return v

def dec(store, key, compressed=False):
    v = stored(store, key)
    if v is None: return None
    raw = base64.b64decode(v)
    if compressed: raw = zlib.decompress(raw)
    return cbor(raw)[0]

def rowdict(row):
    # A scalar row is a CBOR map, or an array when its keys run 1..n.
    if isinstance(row, list):
        return {i + 1: v for i, v in enumerate(row) if v is not None}
    if isinstance(row, dict):
        return {(k.decode() if isinstance(k, bytes) else k): v for k, v in row.items()}
    return row

def entity(store, prefix, id, tablefields):
    row = rowdict(dec(store, f"X-{prefix}-{id}-S"))
    if row is None: return None
    out = {k: v for k, v in row.items() if k != "p"} if isinstance(row, dict) else {}
    for f in tablefields:
        v = dec(store, f"X-{prefix}-{id}-{f}")
        if v is not None: out[f] = v
    return out
