#!/usr/bin/env python3
# Generate english_lng.inc from ENGLISH.LNG, decoding EXACTLY as se_util.pas
# LoadS does: X = record bytes 1..83 (1-indexed); take X[6..80] (75 bytes),
# cut at first NUL, then RTrim (strip trailing spaces). Records 1..103 map to
# Lang^[1..103]; record 0 is discarded by LoadS.
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
LNG = os.path.join(HERE, 'ENGLISH.LNG')
INC = os.path.join(HERE, 'english_lng.inc')

REC = 83          # bytes per record
LANGCNT = 103     # sedit.inc: LangCnt = 103  -> Array[1..103]
FIELD_OFS = 5     # X[6] is 1-indexed -> byte offset 5 within the record
FIELD_LEN = 75

data = open(LNG, 'rb').read()
nrec = len(data) // REC
assert len(data) % REC == 0, f"{len(data)} not a multiple of {REC}"
print(f"# file={len(data)} bytes, {nrec} records (0..{nrec-1})", file=sys.stderr)
assert nrec >= LANGCNT + 1, f"need at least {LANGCNT+1} records, have {nrec}"

def decode(recno):
    base = recno * REC
    raw = data[base + FIELD_OFS : base + FIELD_OFS + FIELD_LEN]  # 75 bytes
    nul = raw.find(0)
    if nul != -1:
        raw = raw[:nul]
    # RTrim: strip trailing spaces (0x20) — matches RTrim() on the Pascal side
    raw = raw.rstrip(b' ')
    return raw

def pascal_literal(b: bytes) -> str:
    # Emit a Pascal string constant: printable ASCII in quoted runs,
    # single-quote doubled, everything else (high bytes, controls) as #NNN.
    if len(b) == 0:
        return "''"
    out = []
    in_quote = False
    for byte in b:
        printable = 0x20 <= byte <= 0x7E
        if printable:
            if not in_quote:
                out.append("'")
                in_quote = True
            if byte == 0x27:  # single quote
                out.append("''")
            else:
                out.append(chr(byte))
        else:
            if in_quote:
                out.append("'")
                in_quote = False
            out.append(f"#{byte}")
    if in_quote:
        out.append("'")
    return "".join(out)

# Reference dump to stderr
for n in range(1, LANGCNT + 1):
    print(f"[{n:3}] {decode(n)!r}", file=sys.stderr)

lines = []
lines.append("{ english_lng.inc - GENERATED from ENGLISH.LNG by scratchpad/genlng.py.")
lines.append("  Do not hand-edit: regenerate from the .LNG. Pure ASCII (0 high bytes);")
lines.append("  CP437 box-art bytes are emitted as #NNN so the Edit/Write encoding trap")
lines.append("  cannot corrupt this file. Index N == ENGLISH.LNG record N == Lang^[N]. }")
lines.append("Const")
lines.append(f" EmbeddedLang : Array[1..{LANGCNT}] Of String[{FIELD_LEN}] = (")
for n in range(1, LANGCNT + 1):
    lit = pascal_literal(decode(n))
    if n == LANGCNT:
        lines.append(f"  {lit});")
    else:
        lines.append(f"  {lit},")
out = "\n".join(lines) + "\n"
open(INC, 'w', encoding='ascii').write(out)
print(f"# wrote src/english_lng.inc ({len(out)} bytes)", file=sys.stderr)
