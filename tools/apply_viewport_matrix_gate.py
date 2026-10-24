"""One-shot: gate multi-viewport loops in tests/*.gd behind DAO_VIEWPORT_MATRIX=full.

Only lists whose first element is 1280x720 are rewritten. Idempotent.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent / "tests"
PAT = re.compile(r"\[\s*(Vector2i?\(\s*1280\s*,\s*720\s*\)\s*(?:,\s*Vector2i?\([^()\]]*\)\s*)+)\]")
GATE = 'OS.get_environment("DAO_VIEWPORT_MATRIX") == "full"'

total = 0
for path in sorted(ROOT.glob("*.gd")):
    text = path.read_bytes().decode("utf-8")

    def repl(m):
        if text[m.end():].lstrip().startswith(f"if {GATE}"):
            return m.group(0)
        nonlocal_count[0] += 1
        body = m.group(1).strip()
        first = re.match(r"Vector2i?\([^()]*\)", body).group(0)
        return f"([{body}] if {GATE} else [{first}])"

    nonlocal_count = [0]
    new = PAT.sub(repl, text)
    if nonlocal_count[0]:
        path.write_bytes(new.encode("utf-8"))
        total += nonlocal_count[0]
        print(f"{path.name}: {nonlocal_count[0]}")
print("TOTAL", total)
