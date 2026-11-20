# Quest data tools (not shipped)

Regenerate QuestData.lua from a QuestieDB Forever release:

1. Unzip QuestieDB-<version>-Forever.zip into a folder x/ next to these scripts.
2. python -I tools/extract.py (writes paladin_quests.json)
3. python -I tools/gen_questdata.py (writes QuestData.lua)

The scripts only read QuestieDB's stored data; none of its code runs. Paths inside are set for the author's machine.
