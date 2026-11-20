# Builds the release zip from the last commit: one ZyrumisLibram/ root folder
# (named like the .toc, as CurseForge requires), forward-slash paths, and only
# the files the game needs. Run from the repo: python -I tools/build_zip.py
import io, os, re, subprocess, tarfile, zipfile

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SKIP_DIRS = ("tools/", "art/")
SKIP_FILES = {"CURSEFORGE.md", ".gitignore"}

toc = open(os.path.join(REPO, "ZyrumisLibram.toc"), encoding="utf-8").read()
version = re.search(r"^## Version: (\S+)", toc, re.M).group(1)
out = os.path.join(REPO, "..", "ZyrumisLibram-%s.zip" % version)

data = subprocess.run(["git", "-C", REPO, "archive", "--format=tar", "HEAD"], capture_output=True, check=True).stdout
names = []
with tarfile.open(fileobj=io.BytesIO(data)) as t, zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for m in t.getmembers():
        if m.isfile() and m.name not in SKIP_FILES and not m.name.startswith(SKIP_DIRS):
            z.writestr("ZyrumisLibram/" + m.name, t.extractfile(m).read())
            names.append(m.name)
print("built", os.path.normpath(out), "with", len(names), "files")
